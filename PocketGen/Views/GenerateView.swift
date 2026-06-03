import SwiftUI

/// The Create screen: compose a prompt, generate, then save or share.
/// Until the model bundle is downloaded the composer is replaced by a one-tap
/// download card; once the free allowance is spent, Generate routes to the unlock.
struct GenerateView: View {
    @StateObject private var model: GenerationViewModel
    @ObservedObject private var modelManager: ModelManager
    @ObservedObject private var entitlements: EntitlementStore

    @State private var showingPaywall = false

    init(gallery: GalleryStore, modelManager: ModelManager, entitlements: EntitlementStore) {
        _model = StateObject(wrappedValue: GenerationViewModel(
            engine: CoreMLGenerationEngine(modelManager: modelManager),
            gallery: gallery,
            entitlements: entitlements
        ))
        self.modelManager = modelManager
        self.entitlements = entitlements
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                switch model.phase {
                case .idle, .failed:
                    composer
                case .generating(let progress):
                    GeneratingView(progress: progress) { model.cancel() }
                case .finished:
                    if let result = model.result {
                        ResultView(result: result) { model.reset() }
                    }
                }
            }
            .navigationTitle("PocketGen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingPaywall) {
                PaywallView(entitlements: entitlements)
            }
        }
    }

    // MARK: - Composer

    private var composer: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let banner = model.deviceTier.banner {
                    Label(banner, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.yellow)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                }

                if modelManager.isReady {
                    promptComposer
                } else {
                    ModelDownloadCard(modelManager: modelManager)
                }

                privacyFooter
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    @ViewBuilder
    private var promptComposer: some View {
        PromptField(
            title: "Prompt",
            placeholder: "A serene mountain lake at sunrise, oil painting…",
            text: $model.request.prompt,
            minHeight: 120
        )

        sizePicker

        advanced

        if case .failed(let message) = model.phase {
            Label(message, systemImage: "xmark.octagon.fill")
                .font(.footnote)
                .foregroundStyle(.red)
        }

        VStack(spacing: 8) {
            Button(action: generateTapped) {
                Label("Generate", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!model.canGenerate)

            Text("Takes \(model.estimatedDuration) on this device")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

            if !entitlements.isUnlocked {
                allowanceFooter
            }
        }
    }

    /// Routes to the unlock screen once the free allowance is spent (PRD: the meter
    /// is the only thing that's ever paid — features are identical free vs. paid).
    private func generateTapped() {
        if entitlements.canGenerate {
            model.generate()
        } else {
            showingPaywall = true
        }
    }

    private var allowanceFooter: some View {
        Group {
            if entitlements.remainingFree > 0 {
                Text("\(entitlements.remainingFree) of \(EntitlementStore.freeAllowance) free creations left")
            } else {
                Button("Free creations used — unlock unlimited") {
                    showingPaywall = true
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var sizePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Size").font(.subheadline.weight(.semibold))
            Picker("Size", selection: $model.request.size) {
                ForEach(ImageSize.allCases) { size in
                    Text(size.label).tag(size)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    /// Negative prompt, steps, and seed live behind a collapsed disclosure so the
    /// first-run experience is one text field and a button (PRD: simple composer).
    private var advanced: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 16) {
                PromptField(
                    title: "Negative prompt (optional)",
                    placeholder: "blurry, low quality, text",
                    text: $model.request.negativePrompt,
                    minHeight: 64
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Steps").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(model.request.steps)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(model.request.steps) },
                            set: { model.request.steps = Int($0) }
                        ),
                        in: GenerationRequest.stepRange,
                        step: 1
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Seed").font(.subheadline.weight(.semibold))
                    TextField("Random", text: seedText)
                        .keyboardType(.numberPad)
                        .padding(10)
                        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                    Text("Same prompt, settings, and seed always recreate the same image.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 12)
        } label: {
            Text("Advanced")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    /// Optional seed as text: empty or unparseable input means "random at generate time".
    private var seedText: Binding<String> {
        Binding(
            get: { model.request.seed.map(String.init) ?? "" },
            set: { model.request.seed = UInt32($0) }
        )
    }

    private var privacyFooter: some View {
        Label(
            "Runs on your device. Your prompts and images never leave your iPhone.",
            systemImage: "lock.shield"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }
}

/// A titled, multiline text entry with a visible bordered area.
private struct PromptField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                TextEditor(text: $text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: minHeight)
            }
            .padding(8)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    GenerateView(gallery: GalleryStore(), modelManager: ModelManager(), entitlements: EntitlementStore())
        .preferredColorScheme(.dark)
}

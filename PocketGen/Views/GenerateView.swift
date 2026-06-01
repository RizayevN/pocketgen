import SwiftUI

/// The Create screen: compose a prompt, generate, then save or share.
struct GenerateView: View {
    @StateObject private var model: GenerationViewModel

    init(gallery: GalleryStore) {
        _model = StateObject(wrappedValue: GenerationViewModel(gallery: gallery))
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

                PromptField(
                    title: "Prompt",
                    placeholder: "A serene mountain lake at sunrise, oil painting…",
                    text: $model.request.prompt,
                    minHeight: 120
                )

                PromptField(
                    title: "Negative prompt (optional)",
                    placeholder: "blurry, low quality, text",
                    text: $model.request.negativePrompt,
                    minHeight: 64
                )

                settings

                if case .failed(let message) = model.phase {
                    Label(message, systemImage: "xmark.octagon.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button(action: model.generate) {
                    Label("Generate", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canGenerate)

                privacyFooter
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Size").font(.subheadline.weight(.semibold))
                Picker("Size", selection: $model.request.size) {
                    ForEach(ImageSize.allCases) { size in
                        Text(size.label).tag(size)
                    }
                }
                .pickerStyle(.segmented)
            }

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
        }
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
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
    GenerateView(gallery: GalleryStore())
        .preferredColorScheme(.dark)
}

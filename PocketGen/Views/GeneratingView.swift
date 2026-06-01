import SwiftUI

/// Shown while the engine works: animated progress with a cancel affordance.
struct GeneratingView: View {
    let progress: Double
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: max(0.001, progress))
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .blue, .cyan, .purple],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.2), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 180, height: 180)

            Text("Generating on device…")
                .font(.headline)
            Text("Nothing is being uploaded.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button(role: .cancel, action: onCancel) {
                Text("Cancel").frame(maxWidth: 200)
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding(40)
    }
}

#Preview {
    GeneratingView(progress: 0.42, onCancel: {})
        .preferredColorScheme(.dark)
}

import SwiftUI

/// A transient error banner shown at the bottom of the screen.
struct ToastView: View {
    @Binding var toast: ActionRunner.Toast?

    var body: some View {
        ZStack {
            if let toast {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(toast.message)
                        .font(.callout)
                        .accessibilityIdentifier("toast.message")
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.thickMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onTapGesture { dismiss() }
                .task(id: toast.id) {
                    try? await Task.sleep(for: .seconds(4))
                    dismiss()
                }
                .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(.snappy, value: toast)
        .sensoryFeedback(.error, trigger: toast?.id) { _, new in new != nil }
    }

    private func dismiss() {
        toast = nil
    }
}

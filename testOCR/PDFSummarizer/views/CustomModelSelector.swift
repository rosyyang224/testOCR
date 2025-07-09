import SwiftUI

struct CustomModelSelector: View {
    @Binding var selectedModel: SummarizerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.primaryText)

            HStack(spacing: 0) {
                ToggleButton(
                    title: "Foundation",
                    isSelected: selectedModel == .foundation,
                    position: .leading
                ) {
                    selectedModel = .foundation
                }

                ToggleButton(
                    title: "Qwen",
                    isSelected: selectedModel == .qwen,
                    position: .trailing
                ) {
                    selectedModel = .qwen
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.mediumGray, lineWidth: 1)
            )
        }
        .padding(.vertical, 8)
    }
}

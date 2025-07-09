import SwiftUI

struct ScanAgainButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.subtitleFont)
                .foregroundColor(AppTheme.primaryButtonTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.primaryGradient)
                        .shadow(color: AppTheme.primaryBlue.opacity(0.4), radius: 6, x: 0, y: 3)
                )
        }
    }
}

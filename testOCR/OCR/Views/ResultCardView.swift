import SwiftUI

struct ResultCardView: View {
    let title: String
    let subtitle: String?
    let iconName: String
    let color: Color

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(AppTheme.titleText)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.cardShadowColor, radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal)
    }
}

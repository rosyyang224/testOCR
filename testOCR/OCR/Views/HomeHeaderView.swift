import SwiftUI

struct HomeHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icon container (colored circle)
            Circle()
                .fill(AppTheme.primaryColor)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "doc.text.viewfinder") // Or replace with actual app icon
                        .foregroundColor(.white)
                        .imageScale(.large)
                )

            Text("PassportScan")
                .font(AppTheme.largeTitle)
                .foregroundColor(AppTheme.titleText)

            Text("Extract passport information instantly")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }
}

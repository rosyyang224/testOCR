import SwiftUI

struct HomeMainCardView: View {
    var onScanTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            PassportIllustration()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(AppTheme.lightGray)
                .cornerRadius(16)

            Text("Scan or upload your passport to extract information automatically")
                .font(AppTheme.subtitleFont)
                .foregroundColor(AppTheme.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button(action: onScanTapped) {
                Text("Scan Passport")
                    .frame(maxWidth: .infinity)
            }
            .modifier(AppTheme.primaryButtonStyle())
            .frame(height: 56)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

import SwiftUI

struct HomeQuickActionsView: View {
    var onRecentScansTapped: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onRecentScansTapped) {
                Text("Recent Scans")
                    .frame(maxWidth: .infinity)
            }
            .modifier(AppTheme.secondaryButtonStyle())
        }
        .padding(.horizontal)
    }
}

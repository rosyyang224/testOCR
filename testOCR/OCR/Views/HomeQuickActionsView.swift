import SwiftUI

struct HomeQuickActionsView: View {
    var onRecentScansTapped: () -> Void
    var onHelpTapped: (() -> Void)?
    var onSettingsTapped: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            // Main recent scans button
            Button(action: onRecentScansTapped) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.primaryColor)
                    
                    Text("Recent Scans")
                        .font(AppTheme.subtitleFont)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .modifier(AppTheme.secondaryButtonStyle())
            
            // Additional quick action buttons
            HStack(spacing: 12) {
                // Help button
                Button(action: onHelpTapped ?? {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text("Help")
                            .font(AppTheme.bodyFont)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .modifier(AppTheme.secondaryButtonStyle())
                
                // Settings button
                Button(action: onSettingsTapped ?? {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "gear")
                            .font(.system(size: 16, weight: .medium))
                        Text("Settings")
                            .font(AppTheme.bodyFont)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                }
                .modifier(AppTheme.secondaryButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

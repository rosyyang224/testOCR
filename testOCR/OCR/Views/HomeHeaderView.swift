import SwiftUI

struct HomeHeaderView: View {
    @State private var animateIcon = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Enhanced icon container with gradient and animation
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Animated background circle
                Circle()
                    .stroke(AppTheme.primaryBlue.opacity(0.2), lineWidth: 2)
                    .frame(width: 90, height: 90)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .opacity(animateIcon ? 0.5 : 0.8)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                
                Image(systemName: "doc.text.viewfinder")
                    .foregroundColor(.white)
                    .font(.system(size: 28, weight: .medium))
                    .scaleEffect(animateIcon ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateIcon
                    )
            }
            .onAppear {
                animateIcon = true
            }
            
            VStack(spacing: 8) {
                Text("PassportScan")
                    .font(AppTheme.largeTitle)
                    .foregroundColor(AppTheme.titleText)
                    .tracking(0.5) // Slightly increased letter spacing
                
                Text("Extract passport information instantly")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}

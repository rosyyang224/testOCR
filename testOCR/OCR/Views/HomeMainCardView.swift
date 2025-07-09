import SwiftUI

struct HomeMainCardView: View {
    var onScanTapped: () -> Void
    @State private var isDragOver = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 28) {
            // Enhanced passport illustration area with drag-and-drop styling
            ZStack {
                // Background with subtle gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppTheme.lightGray,
                                AppTheme.mediumGray.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 220)
                    .overlay(
                        // Dashed border for drag-and-drop indication
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isDragOver ? AppTheme.primaryColor : AppTheme.mediumGray,
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                            )
                            .opacity(isDragOver ? 1.0 : 0.6)
                            .animation(AppTheme.defaultAnimation, value: isDragOver)
                    )
                
                VStack(spacing: 16) {
                    // Enhanced passport icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.primaryColor)
                            .frame(width: 80, height: 100)
                            .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        VStack(spacing: 4) {
                            Circle()
                                .fill(AppTheme.primaryColor.opacity(0.3))
                                .frame(width: 20, height: 20)
                            
                            Text("PASSPORT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                    
                    // File type indicators
                    HStack(spacing: 12) {
                        ForEach(["JPG", "PNG", "PDF"], id: \.self) { fileType in
                            Text(fileType)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.8))
                                )
                        }
                    }
                }
            }
            .onAppear {
                pulseAnimation = true
            }
            .onDrop(of: ["public.image"], isTargeted: $isDragOver) { providers in
                // Handle file drop
                return true
            }
            
            // Enhanced description text
            VStack(spacing: 8) {
                Text("Scan or upload your passport")
                    .font(AppTheme.subtitleFont)
                    .foregroundColor(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Information will be extracted automatically")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            // Enhanced primary button with better styling
            Button(action: onScanTapped) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Scan Passport")
                        .font(AppTheme.subtitleFont)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
            }
            .modifier(AppTheme.primaryButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 32)
        .background(Color.white)
        .modifier(AppTheme.cardStyle())
        .padding(.horizontal, 20)
    }
}

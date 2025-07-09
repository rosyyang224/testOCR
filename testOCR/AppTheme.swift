import SwiftUI

struct AppTheme {
    // MARK: - Enhanced Color Palette
    static let primaryBlue = Color(red: 0.0, green: 0.48, blue: 0.8)
    static let lightBlue = Color(red: 0.2, green: 0.6, blue: 0.9)
    static let darkBlue = Color(red: 0.0, green: 0.32, blue: 0.64)
    
    // Added gradient colors for more modern look
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [primaryBlue, lightBlue]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let primaryGray = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let secondaryGray = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let lightGray = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let mediumGray = Color(red: 0.9, green: 0.9, blue: 0.9)
    
    // Enhanced background colors
    static let backgroundColor = Color(red: 0.98, green: 0.98, blue: 0.98) // Slightly off-white
    static let cardShadowColor = Color.black.opacity(0.08)
    
    static let successGreen = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let errorRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    // MARK: - Semantic Assignments
    static let primaryColor = primaryBlue
    static let secondaryColor = primaryGray
    static let cardBackground = lightGray
    static let accentColor = lightBlue
    
    static let primaryText = primaryGray
    static let secondaryText = secondaryGray
    static let titleText = darkBlue
    
    static let highConfidenceColor = successGreen
    static let mediumConfidenceColor = warningOrange
    static let lowConfidenceColor = errorRed
    
    // MARK: - Enhanced Typography
    static let largeTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let titleFont = Font.system(size: 24, weight: .bold, design: .rounded)
    static let subtitleFont = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .medium)
    static let captionFont = Font.system(size: 14, weight: .medium)
    static let smallFont = Font.system(size: 12, weight: .medium)
    
    // MARK: - Animation Constants
    static let defaultAnimation = Animation.easeInOut(duration: 0.3)
    static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let buttonPressAnimation = Animation.easeInOut(duration: 0.1)
    
    // MARK: - SwiftUI Style Helpers
    static func textFieldStyle(isEditable: Bool = true) -> some ViewModifier {
        ModifiedTextFieldStyle(isEditable: isEditable)
    }
    
    static func primaryButtonStyle() -> some ViewModifier {
        PrimaryButtonStyle()
    }
    
    static func secondaryButtonStyle() -> some ViewModifier {
        SecondaryButtonStyle()
    }
    
    static func cardStyle() -> some ViewModifier {
        CardViewStyle()
    }
    
    static func confidenceColor(for confidence: Float) -> Color {
        switch confidence {
        case 0.8...1.0:
            return highConfidenceColor
        case 0.5..<0.8:
            return mediumConfidenceColor
        default:
            return lowConfidenceColor
        }
    }
}

// MARK: - Enhanced ViewModifiers

private struct ModifiedTextFieldStyle: ViewModifier {
    let isEditable: Bool
    
    func body(content: Content) -> some View {
        content
            .font(AppTheme.bodyFont)
            .padding(14)
            .background(isEditable ? Color.white : AppTheme.cardBackground)
            .foregroundColor(isEditable ? AppTheme.primaryText : AppTheme.secondaryText)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isEditable ? AppTheme.primaryColor : AppTheme.mediumGray, lineWidth: 1.5)
            )
            .cornerRadius(12)
    }
}

private struct PrimaryButtonStyle: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .font(AppTheme.subtitleFont)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.primaryGradient)
                    .shadow(color: AppTheme.primaryBlue.opacity(0.4), radius: 8, x: 0, y: 4)
            )
            .foregroundColor(Color.white)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(AppTheme.buttonPressAnimation, value: isPressed)
            .onTapGesture {
                // Handle tap feedback
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

private struct SecondaryButtonStyle: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .font(AppTheme.subtitleFont)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(AppTheme.lightGray)
            .foregroundColor(AppTheme.primaryText)
            .cornerRadius(16)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(AppTheme.buttonPressAnimation, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

private struct CardViewStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: AppTheme.cardShadowColor, radius: 12, x: 0, y: 6)
    }
}

// MARK: - Color Aliases for Button Styles
extension AppTheme {
    static let primaryButtonColor = primaryBlue
    static let primaryButtonTextColor = Color.white
    static let secondaryButtonColor = mediumGray
    static let secondaryButtonTextColor = primaryGray
}

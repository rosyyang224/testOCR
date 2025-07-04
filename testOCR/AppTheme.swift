import SwiftUI

struct AppTheme {
    // MARK: - Color Palette (SwiftUI Color)
    static let primaryBlue = Color(red: 0.0, green: 0.48, blue: 0.8)
    static let lightBlue = Color(red: 0.2, green: 0.6, blue: 0.9)
    static let darkBlue = Color(red: 0.0, green: 0.32, blue: 0.64)

    static let primaryGray = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let secondaryGray = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let lightGray = Color(red: 0.95, green: 0.95, blue: 0.95)
    static let mediumGray = Color(red: 0.9, green: 0.9, blue: 0.9)

    static let successGreen = Color(red: 0.2, green: 0.7, blue: 0.3)
    static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.0)
    static let errorRed = Color(red: 0.9, green: 0.2, blue: 0.2)

    // MARK: - Semantic Assignments
    static let primaryColor = primaryBlue
    static let secondaryColor = primaryGray
    static let backgroundColor = Color.white
    static let cardBackground = lightGray
    static let accentColor = lightBlue

    static let primaryText = primaryGray
    static let secondaryText = secondaryGray
    static let titleText = darkBlue

    static let highConfidenceColor = successGreen
    static let mediumConfidenceColor = warningOrange
    static let lowConfidenceColor = errorRed

    // MARK: - Typography
    static let largeTitle = Font.system(size: 28, weight: .bold)
    static let titleFont = Font.system(size: 24, weight: .bold)
    static let subtitleFont = Font.system(size: 18, weight: .semibold)
    static let bodyFont = Font.system(size: 16)
    static let captionFont = Font.system(size: 14)
    static let smallFont = Font.system(size: 12)

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

// MARK: - Custom ViewModifiers

private struct ModifiedTextFieldStyle: ViewModifier {
    let isEditable: Bool

    func body(content: Content) -> some View {
        content
            .font(AppTheme.bodyFont)
            .padding(10)
            .background(isEditable ? Color.white : AppTheme.cardBackground)
            .foregroundColor(isEditable ? AppTheme.primaryText : AppTheme.secondaryText)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isEditable ? AppTheme.primaryColor : AppTheme.mediumGray, lineWidth: 1)
            )
            .cornerRadius(8)
    }
}

private struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.subtitleFont)
            .padding()
            .background(AppTheme.primaryButtonColor)
            .foregroundColor(Color.white)
            .cornerRadius(12)
            .shadow(color: AppTheme.primaryBlue.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

private struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(AppTheme.subtitleFont)
            .padding()
            .background(AppTheme.secondaryButtonColor)
            .foregroundColor(AppTheme.secondaryButtonTextColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.mediumGray, lineWidth: 1)
            )
            .cornerRadius(12)
    }
}

private struct CardViewStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Color Aliases for Button Styles

extension AppTheme {
    static let primaryButtonColor = primaryBlue
    static let primaryButtonTextColor = Color.white
    static let secondaryButtonColor = mediumGray
    static let secondaryButtonTextColor = primaryGray
}

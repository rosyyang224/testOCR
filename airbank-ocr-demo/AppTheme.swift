import UIKit

struct AppTheme {
    // MARK: - Professional Blue & Gray Color Palette
    
    // Primary Blues (for main actions, headers, important elements)
    static let primaryBlue = UIColor(red: 0.0, green: 0.48, blue: 0.8, alpha: 1.0) // #007ACC
    static let lightBlue = UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)   // #3399E6
    static let darkBlue = UIColor(red: 0.0, green: 0.32, blue: 0.64, alpha: 1.0)  // #0052A3
    
    // Professional Grays (for text, backgrounds, secondary elements)
    static let primaryGray = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)     // #333333
    static let secondaryGray = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)   // #666666
    static let lightGray = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)    // #F2F2F2
    static let mediumGray = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)      // #E6E6E6
    
    // Status Colors (for confidence indicators, validation)
    static let successGreen = UIColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)    // #33B34D
    static let warningOrange = UIColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 1.0)   // #FF9900
    static let errorRed = UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)        // #E63333
    
    // MARK: - Semantic Color Assignments
    
    // Main colors for passport OCR app
    static let primaryColor = primaryBlue          // Main buttons, headers
    static let secondaryColor = primaryGray        // Body text, labels
    static let backgroundColor = UIColor.white     // Main background
    static let cardBackground = lightGray          // Card/field backgrounds
    static let accentColor = lightBlue            // Interactive elements, links
    
    // Text colors
    static let primaryText = primaryGray          // Main text
    static let secondaryText = secondaryGray      // Secondary text, hints
    static let titleText = darkBlue              // Titles, important headings
    
    // Button colors
    static let primaryButtonColor = primaryBlue
    static let primaryButtonTextColor = UIColor.white
    static let secondaryButtonColor = mediumGray
    static let secondaryButtonTextColor = primaryGray
    
    // Status indicators (for confidence levels)
    static let highConfidenceColor = successGreen    // Green for high confidence
    static let mediumConfidenceColor = warningOrange  // Orange for medium confidence
    static let lowConfidenceColor = errorRed         // Red for low confidence
    
    // MARK: - Typography
    
    static let largeTitle = UIFont.boldSystemFont(ofSize: 28)      // Screen titles
    static let titleFont = UIFont.boldSystemFont(ofSize: 24)       // Section headers
    static let subtitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold) // Subsections
    static let bodyFont = UIFont.systemFont(ofSize: 16)           // Body text
    static let captionFont = UIFont.systemFont(ofSize: 14)        // Labels, hints
    static let smallFont = UIFont.systemFont(ofSize: 12)          // Fine print
    
    // MARK: - UI Component Styling
    
    static func apply() {
        // Navigation Bar
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = backgroundColor
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: titleText,
            .font: titleFont
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: titleText,
            .font: largeTitle
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = primaryColor
        
        // Bar Button Items
        UIBarButtonItem.appearance().tintColor = primaryColor
        
        // Buttons - will be customized per button type in view controllers
        
        // Tab Bar (if using tab navigation)
        UITabBar.appearance().backgroundColor = backgroundColor
        UITabBar.appearance().tintColor = primaryColor
        UITabBar.appearance().unselectedItemTintColor = secondaryGray
        
        // Table Views
        UITableView.appearance().backgroundColor = backgroundColor
        UITableView.appearance().separatorColor = mediumGray
        
        // Text Fields (for editable passport fields)
        UITextField.appearance().textColor = primaryText
        UITextField.appearance().tintColor = primaryColor
    }
    
    // MARK: - Helper Methods for Custom Styling
    
    static func styleTextField(_ textField: UITextField, isEditable: Bool = true) {
        textField.font = bodyFont
        textField.textColor = isEditable ? primaryText : secondaryText
        textField.backgroundColor = isEditable ? UIColor.white : cardBackground
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = isEditable ? primaryColor.cgColor : mediumGray.cgColor
        textField.layer.cornerRadius = 8.0
        textField.layer.masksToBounds = true
        
        // Padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always
    }
    
    static func stylePrimaryButton(_ button: UIButton) {
        button.backgroundColor = primaryButtonColor
        button.setTitleColor(primaryButtonTextColor, for: .normal)
        button.titleLabel?.font = subtitleFont
        button.layer.cornerRadius = 12.0
        button.layer.masksToBounds = true
        
        // Add shadow for depth
        button.layer.shadowColor = primaryBlue.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4.0
        button.layer.shadowOpacity = 0.3
        button.layer.masksToBounds = false
    }
    
    static func styleSecondaryButton(_ button: UIButton) {
        button.backgroundColor = secondaryButtonColor
        button.setTitleColor(secondaryButtonTextColor, for: .normal)
        button.titleLabel?.font = subtitleFont
        button.layer.cornerRadius = 12.0
        button.layer.borderWidth = 1.0
        button.layer.borderColor = mediumGray.cgColor
        button.layer.masksToBounds = true
    }
    
    static func styleCardView(_ view: UIView) {
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 12.0
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4.0
        view.layer.shadowOpacity = 0.1
        view.layer.masksToBounds = false
    }
    
    // Confidence indicator colors
    static func confidenceColor(for confidence: Float) -> UIColor {
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

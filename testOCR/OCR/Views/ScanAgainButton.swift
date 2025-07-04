import SwiftUI

struct ScanAgainButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Scan Another")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppTheme.primaryColor)
                .cornerRadius(12)
        }
    }
}

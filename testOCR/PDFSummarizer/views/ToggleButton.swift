import SwiftUI

enum ToggleButtonPosition {
    case leading
    case trailing
}

enum Corner {
    case topLeft, topRight, bottomLeft, bottomRight
}

struct RoundedCornersShape: Shape {
    let corners: [Corner]
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topLeft = corners.contains(.topLeft) ? radius : 0
        let topRight = corners.contains(.topRight) ? radius : 0
        let bottomLeft = corners.contains(.bottomLeft) ? radius : 0
        let bottomRight = corners.contains(.bottomRight) ? radius : 0

        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.minY))

        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - topRight, y: rect.minY + topRight),
                    radius: topRight,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false)

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRight))
        path.addArc(center: CGPoint(x: rect.maxX - bottomRight, y: rect.maxY - bottomRight),
                    radius: bottomRight,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)

        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + bottomLeft, y: rect.maxY - bottomLeft),
                    radius: bottomLeft,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)

        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addArc(center: CGPoint(x: rect.minX + topLeft, y: rect.minY + topLeft),
                    radius: topLeft,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)

        return path
    }
}

struct ToggleButton: View {
    let title: String
    let isSelected: Bool
    let position: ToggleButtonPosition
    let action: () -> Void

    private let cornerRadius: CGFloat = 12

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundColor(isSelected ? .white : AppTheme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    (isSelected ? AnyView(AppTheme.primaryGradient) : AnyView(AppTheme.lightGray))
                        .clipShape(RoundedCornersShape(corners: roundedCorners(for: position), radius: cornerRadius))
                )
                .overlay(
                    RoundedCornersShape(corners: roundedCorners(for: position), radius: cornerRadius)
                        .stroke(AppTheme.mediumGray, lineWidth: 1)
                )
        }
        .animation(AppTheme.buttonPressAnimation, value: isSelected)
    }

    private func roundedCorners(for position: ToggleButtonPosition) -> [Corner] {
        switch position {
        case .leading:
            return [.topLeft, .bottomLeft]
        case .trailing:
            return [.topRight, .bottomRight]
        }
    }
}

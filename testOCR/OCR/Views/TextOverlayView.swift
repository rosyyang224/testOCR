import SwiftUI
import Vision

struct TextOverlay: View {
    let observations: [VNRecognizedTextObservation]
    let additionalBoxes: [(CGRect, Color, CGFloat)] // (normalized rect, color, line width)
    let imageSize: CGSize

    var body: some View {
        GeometryReader { geometry in
            let scaleX = geometry.size.width
            let scaleY = geometry.size.height

            ZStack {
                // Draw Vision text boxes
                ForEach(observations.indices, id: \.self) { i in
                    let obs = observations[i]
                    let rect = normalizedRectToViewRect(obs.boundingBox, in: geometry.size)

                    Rectangle()
                        .stroke(Color.yellow.opacity(0.75), lineWidth: 2)
                        .cornerRadius(6)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)

                    if let text = obs.topCandidates(1).first?.string {
                        Text(text)
                            .font(.system(size: 5))
                            .foregroundColor(.red)
                            .position(x: rect.minX + 4, y: rect.minY + 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Draw custom colored boxes
                ForEach(additionalBoxes.indices, id: \.self) { i in
                    let (normalized, color, width) = additionalBoxes[i]
                    let rect = normalizedRectToViewRect(normalized, in: geometry.size)

                    Rectangle()
                        .stroke(color.opacity(0.8), lineWidth: width)
                        .cornerRadius(8)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
        }
        .clipped()
    }

    private func normalizedRectToViewRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x * size.width,
            y: (1 - rect.origin.y - rect.height) * size.height,
            width: rect.width * size.width,
            height: rect.height * size.height
        )
    }
}

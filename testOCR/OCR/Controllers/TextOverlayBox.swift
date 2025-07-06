import SwiftUI
import Vision

struct TextOverlayBox: View {
    var observations: [VNRecognizedTextObservation]

    var body: some View {
        GeometryReader { geometry in
            ForEach(observations.indices, id: \.self) { index in
                let obs = observations[index]
                let rect = convert(obs.boundingBox, in: geometry.size)
                let text = obs.topCandidates(1).first?.string ?? ""

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.yellow.opacity(0.8), lineWidth: 2)
                        .background(Color.clear)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)

                    Text(text)
                        .font(.system(size: 6))
                        .foregroundColor(.red)
                        .position(x: rect.minX + 4, y: rect.minY + 6) // Adjust padding if needed
                        .frame(maxWidth: rect.width - 4, alignment: .leading)
                }
            }
        }
    }

    private func convert(_ boundingBox: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: boundingBox.origin.x * size.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * size.height,
            width: boundingBox.width * size.width,
            height: boundingBox.height * size.height
        )
    }
}

import SwiftUI
import Vision

struct ResultCardView: View {
    @State var tableData: [RecognizedKeyValue]
    
    let documentType: String
    let image: CGImage?
    let textObservations: [VNRecognizedTextObservation]
    let showTable: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(documentType)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)

            ZStack {
                if let image {
                    Image(decorative: image, scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)

                    TextOverlay(
                        observations: textObservations,
                        additionalBoxes: [],
                        imageSize: CGSize(width: image.width, height: image.height)
                    )
                    .allowsHitTesting(false)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .frame(height: 250)
                }
            }

            if showTable {
                KeyValueTableView(keyValuePairs: $tableData)
                    .frame(maxHeight: 300)
                    .transition(.opacity)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

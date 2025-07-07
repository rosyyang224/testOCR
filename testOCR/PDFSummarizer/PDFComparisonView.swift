import SwiftUI
import CoreGraphics

struct PDFComparisonView: View {
    let pageImages: [CGImage]
    let pageTexts: [String]

    var body: some View {
        ScrollView {
            ForEach(pageImages.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 16) {
                    Text("Page \(index + 1)")
                        .font(.title3)
                        .bold()

                    Image(decorative: pageImages[index], scale: 1.0, orientation: .up)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(10)
                        .shadow(radius: 3)


                    ScrollView(.horizontal) {
                        Text(pageTexts.indices.contains(index) ? pageTexts[index] : "[No extracted text]")
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .fixedSize(horizontal: true, vertical: false)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 32)

                Divider()
            }
        }
        .padding()
        .navigationTitle("Extraction Comparison")
    }
}

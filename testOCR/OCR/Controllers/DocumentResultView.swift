import SwiftUI
import Vision

struct DocumentResultView: View {
    let image: CGImage
    @State private var isImageVisible: Bool = true
    @State private var keyValuePairs: [RecognizedKeyValue] = []
    @State private var detectedDocumentType: String = "Unknown"

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isImageVisible {
                    ZStack(alignment: .topLeading) {
                        Image(decorative: image, scale: 1.0)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 250)

                        TextOverlayBox(observations: keyValuePairs.compactMap { $0.keyTextObservation })
                    }
                }

                Text("Detected: \(detectedDocumentType)")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                if !keyValuePairs.isEmpty {
                    ForEach(keyValuePairs, id: \.key) { pair in
                        KeyValueRowView(key: pair.key, value: pair.value ?? "")
                            .padding(.horizontal)
                    }
                }

                Button("Scan Another") {
                    // Hook to navigation
                }
                .buttonStyle(.borderedProminent)
                .padding()

                Button(isImageVisible ? "Hide Image" : "Show Image") {
                    isImageVisible.toggle()
                }
                .padding(.top, 8)
            }
            .padding(.top)
        }
    }
}

#Preview {
    DocumentResultView(image: CGImage.placeholder)
}

extension CGImage {
    static var placeholder: CGImage {
        let context = CIContext()
        let ciImage = CIImage(color: CIColor(red: 0.9, green: 0.9, blue: 0.95)).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        return context.createCGImage(ciImage, from: ciImage.extent)!
    }
}

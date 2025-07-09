import SwiftUI
import Vision

struct DocumentResultView: View {
    let image: CGImage

    @State private var isImageVisible: Bool = true
    @State private var keyValuePairs: [RecognizedKeyValue] = []
    @State private var detectedDocumentType: String = "Processing..."
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isImageVisible {
                    ZStack {
                        GeometryReader { geo in
                            Image(decorative: image, scale: 1.0)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width)
                                .clipped()
                                .overlay(
                                    TextOverlayBox(observations: keyValuePairs.compactMap { $0.keyTextObservation })
                                )
                        }
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: AppTheme.cardShadowColor, radius: 8, x: 0, y: 4)
                    }
                }

                ResultCardView(
                    title: "Detected Document",
                    subtitle: detectedDocumentType,
                    iconName: "doc.text.magnifyingglass",
                    color: AppTheme.accentColor
                )

                if !keyValuePairs.isEmpty {
                    KeyValueTableView(
                        keyValuePairs: $keyValuePairs,
                        onValueChanged: { index, newValue in
                            keyValuePairs[index].value = newValue
                        }
                    )
                    .padding(.top, 8)
                }
                
                Button(action: saveToJSON) {
                    Text("Save")
                }
                .modifier(AppTheme.primaryButtonStyle())


                ScanAgainButton(title: "Scan Another") {
                    dismiss()
                }

                Button(isImageVisible ? "Hide Image" : "Show Image") {
                    withAnimation { isImageVisible.toggle() }
                }
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.accentColor)
                .padding(.top, 4)
            }
            .padding()
        }
        .background(AppTheme.backgroundColor.ignoresSafeArea())
        .onAppear {
            runFullOCR(on: image)
        }
    }
    
    private func saveToJSON() {
        var idCardDict: [String: String] = [:]

        for pair in keyValuePairs {
            if let value = pair.value {
                idCardDict[pair.key] = value
            }
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: idCardDict, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Saved ID Card JSON:\n\(jsonString)")
            }
        } catch {
            print("Error encoding ID card to JSON: \(error)")
        }
    }

    private func runFullOCR(on cgImage: CGImage) {
        let rectangleRequest = VNDetectRectanglesRequest { request, _ in
            if let rect = request.results?.first as? VNRectangleObservation {
                self.runTextRecognition(cgImage: cgImage, regionOfInterest: rect.boundingBox)
            } else {
                self.runTextRecognition(cgImage: cgImage, regionOfInterest: nil)
            }
        }

        rectangleRequest.minimumConfidence = 0.8
        rectangleRequest.minimumAspectRatio = 0.5
        rectangleRequest.maximumAspectRatio = 1.0

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .right, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([rectangleRequest])
        }
    }

    private func runTextRecognition(cgImage: CGImage, regionOfInterest: CGRect?) {
        let request = VNRecognizeTextRequest { request, error in
            guard error == nil, let results = request.results as? [VNRecognizedTextObservation] else { return }

            let recognizedWords = results.compactMap { obs in
                obs.topCandidates(1).first.map {
                    RecognizedWord(
                        text: $0.string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
                        boundingBox: obs.boundingBox
                    )
                }
            }

            var extractedPairs: [RecognizedKeyValue] = []
            var docType = "Unknown"

            if let parsedLines = MRZProcessor.detectAndPrintMRZ(from: recognizedWords),
               MRZProcessor.isLikelyMRZBlock(parsedLines),
               let parsed = PassportMRZParser.parse(lines: parsedLines.map { $0.text }) {
                docType = "Passport (MRZ)"
                extractedPairs = [
                    .init(key: "SURNAME", value: parsed.surname),
                    .init(key: "GIVEN NAMES", value: parsed.givenNames),
                    .init(key: "PASSPORT NO", value: parsed.passportNumber),
                    .init(key: "DATE OF BIRTH", value: parsed.dateOfBirth),
                    .init(key: "NATIONALITY", value: parsed.nationality),
                    .init(key: "SEX", value: parsed.sex),
                    .init(key: "DATE OF EXPIRY", value: parsed.expirationDate)
                ]
            } else {
                docType = "ID Card"
                let normalizedLines = IDCardLayoutHelper.normalizeObservations(results)
                extractedPairs = IDCardFieldExtractor.extractKeyValuePairs(from: normalizedLines)
            }

            DispatchQueue.main.async {
                self.keyValuePairs = extractedPairs
                self.detectedDocumentType = docType
            }
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["cs_CZ", "en_GB"]
        request.regionOfInterest = regionOfInterest ?? CGRect(x: 0, y: 0, width: 1, height: 1)

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .right, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}

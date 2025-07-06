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
            VStack(spacing: 20) {
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
                        .frame(height: 250) // same height as before
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
                    dismiss()
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
        .onAppear {
            runFullOCR(on: image)
        }
    }

    // MARK: - Vision OCR Logic
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
                    .init(key: "SURNAME", value: parsed.surname, keyTextObservation: nil, valueTextObservation: nil),
                    .init(key: "GIVEN NAMES", value: parsed.givenNames, keyTextObservation: nil, valueTextObservation: nil),
                    .init(key: "PASSPORT NO", value: parsed.passportNumber, keyTextObservation: nil, valueTextObservation: nil),
                    .init(key: "DATE OF BIRTH", value: parsed.dateOfBirth, keyTextObservation: nil, valueTextObservation: nil),
                    .init(key: "NATIONALITY", value: parsed.nationality, keyTextObservation: nil, valueTextObservation: nil),
                    .init(key: "SEX", value: parsed.sex, keyTextObservation: nil, valueTextObservation: nil),
                    .init(key: "DATE OF EXPIRY", value: parsed.expirationDate, keyTextObservation: nil, valueTextObservation: nil)
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

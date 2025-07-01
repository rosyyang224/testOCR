import UIKit
import Vision
import AVFoundation
import StringMetric

final class DocumentResultViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Properties
    private var currentImage: UIImage?
    private var isImageVisible: Bool = true
    private var recognizedKeyValuePairs: [RecognizedKeyValue] = []
    private var detectedDocumentType: String?

    // MARK: - UI Components
    private let resultCardView = ResultCardView()
    private let scanAgainButton = ScanAgainButton()

    private lazy var detectTextRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: handleTextRecognition)
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["cs_CZ", "en_GB"]
        return request
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.backgroundColor
        setupUI()
        setupNavBar()
        resultCardView.tableView.delegate = self
        resultCardView.tableView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let image = currentImage, isImageVisible {
            updateOverlayFrame(for: image)
        }
    }

    // MARK: - Public
    func loadImage(_ image: UIImage) {
        currentImage = image
        resultCardView.imagePreview.image = image
        navigationItem.rightBarButtonItem?.isEnabled = true
        processImage(image)
    }

    // MARK: - Setup
    private func setupNavBar() {
        let toggleButton = UIBarButtonItem(title: isImageVisible ? "Hide Image" : "Show Image",
                                           style: .plain,
                                           target: self,
                                           action: #selector(toggleImageVisibility))
        toggleButton.tintColor = AppTheme.primaryColor
        navigationItem.rightBarButtonItem = toggleButton
    }

    private func setupUI() {
        view.addSubview(resultCardView)
        view.addSubview(scanAgainButton)

        resultCardView.translatesAutoresizingMaskIntoConstraints = false
        scanAgainButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            resultCardView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            resultCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resultCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            scanAgainButton.topAnchor.constraint(equalTo: resultCardView.bottomAnchor, constant: 20),
            scanAgainButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            scanAgainButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            scanAgainButton.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])

        scanAgainButton.addTarget(self, action: #selector(scanAnother), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc private func toggleImageVisibility() {
        isImageVisible.toggle()
        resultCardView.imagePreview.image = isImageVisible ? currentImage : nil
        navigationItem.rightBarButtonItem?.title = isImageVisible ? "Hide Image" : "Show Image"
    }

    @objc private func scanAnother() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - OCR Processing
    private func updateOverlayFrame(for image: UIImage) {
        let imageSize = image.size
        let imageViewSize = resultCardView.imagePreview.bounds.size
        let rect = AVMakeRect(aspectRatio: imageSize, insideRect: CGRect(origin: .zero, size: imageViewSize))
        resultCardView.overlayView.frame = rect
    }

    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let rectangleRequest = VNDetectRectanglesRequest { [weak self] request, _ in
            guard let self = self else { return }
            if let rect = request.results?.first as? VNRectangleObservation {
                DispatchQueue.main.async {
                    self.resultCardView.overlayView.drawBoundingBox(for: rect.boundingBox, color: .green, lineWidth: 2.0)
                }
                self.runOCR(on: cgImage, regionOfInterest: rect.boundingBox)
            } else {
                self.runOCR(on: cgImage, regionOfInterest: nil)
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

    private func runOCR(on cgImage: CGImage, regionOfInterest: CGRect?) {
        detectTextRequest.regionOfInterest = regionOfInterest ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .right, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([self.detectTextRequest])
        }
    }

    private func handleTextRecognition(request: VNRequest?, error: Error?) {
        guard error == nil, let results = request?.results as? [VNRecognizedTextObservation] else { return }
        
//        print("📝 RAW OCR RESULTS:")
//            for obs in results {
//                if let topCandidate = obs.topCandidates(1).first {
//                    print("• \"\(topCandidate.string)\" — box: \(obs.boundingBox)")
//                }
//            }
        
        let recognizedWords = results.compactMap { obs in
            obs.topCandidates(1).first.map {
                RecognizedWord(text: $0.string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), boundingBox: obs.boundingBox)
            }
        }

        let mrzLines = MRZProcessor.detectMRZLines(from: recognizedWords)
        var keyValuePairs: [RecognizedKeyValue] = []

        if let parsedLines = MRZProcessor.detectAndPrintMRZ(from: recognizedWords),
           MRZProcessor.isLikelyMRZBlock(parsedLines),
           let parsed = PassportMRZParser.parse(lines: parsedLines.map { $0.text }) {
            detectedDocumentType = "Passport (MRZ)"
            keyValuePairs = [
                .init(key: "SURNAME", value: parsed.surname, keyTextObservation: nil, valueTextObservation: nil),
                .init(key: "GIVEN NAMES", value: parsed.givenNames, keyTextObservation: nil, valueTextObservation: nil),
                .init(key: "PASSPORT NO", value: parsed.passportNumber, keyTextObservation: nil, valueTextObservation: nil),
                .init(key: "DATE OF BIRTH", value: parsed.dateOfBirth, keyTextObservation: nil, valueTextObservation: nil),
                .init(key: "NATIONALITY", value: parsed.nationality, keyTextObservation: nil, valueTextObservation: nil),
                .init(key: "SEX", value: parsed.sex, keyTextObservation: nil, valueTextObservation: nil),
                .init(key: "DATE OF EXPIRY", value: parsed.expirationDate, keyTextObservation: nil, valueTextObservation: nil)
            ]
        } else {
            detectedDocumentType = "ID Card"
            let normalizedLines = IDCardLayoutHelper.normalizeObservations(results)
            keyValuePairs = IDCardFieldExtractor.extractKeyValuePairs(from: normalizedLines)
            print("🔎 Extracted \(keyValuePairs.count) key-value pairs")

        }

        DispatchQueue.main.async {
            self.resultCardView.overlayView.clear()
            results.forEach { self.resultCardView.overlayView.drawBoundingBox(for: $0) }

            self.detectedDocumentType = self.detectedDocumentType ?? "Unknown"
            self.recognizedKeyValuePairs = keyValuePairs
            self.resultCardView.documentTypeLabel.text = "Detected: \(self.detectedDocumentType!)"
            self.resultCardView.tableView.isHidden = keyValuePairs.isEmpty
            self.resultCardView.tableView.reloadData()
            
            let rowHeight: CGFloat = 44
            let spacing: CGFloat = 12
            let totalHeight = CGFloat(keyValuePairs.count) * rowHeight + spacing
            self.resultCardView.tableHeightConstraint.constant = totalHeight

        }
    }

    // MARK: - UITableView
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recognizedKeyValuePairs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: KeyValueTableViewCell.identifier, for: indexPath) as? KeyValueTableViewCell else {
            return UITableViewCell()
        }
        let pair = recognizedKeyValuePairs[indexPath.row]
        cell.configure(key: pair.key, value: pair.value ?? "")
        return cell
    }
}

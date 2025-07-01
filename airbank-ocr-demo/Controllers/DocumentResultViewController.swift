//
//  DocumentResultViewController.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import UIKit
import Vision
import AVFoundation
import StringMetric

final class DocumentResultViewController: UIViewController,
                                          UITableViewDelegate,
                                          UITableViewDataSource {
    
    private var currentImage: UIImage?
    private var isImageVisible: Bool = true
    private var recognizedKeyValuePairs: [RecognizedKeyValue] = []
    private var detectedDocumentType: String? = nil

    private lazy var detectTextRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: handleTextRecognition)
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["cs_CZ", "en_GB"]
        return request
    }()

    private lazy var imagePreview: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let overlayView = TextOverlayView()

    private lazy var documentTypeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .systemBlue
        return label
    }()

    private lazy var keyValueTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(KeyValueTableViewCell.self, forCellReuseIdentifier: KeyValueTableViewCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.isHidden = true
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupNavBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let image = currentImage, isImageVisible {
            updateOverlayFrame(for: image)
        }
    }

    func loadImage(_ image: UIImage) {
        currentImage = image
        imagePreview.image = image
        navigationItem.rightBarButtonItem?.isEnabled = true
        processImage(image)
    }
    
    private func setupNavBar() {
        let toggleButton = UIBarButtonItem(title: "Hide Image", style: .plain, target: self, action: #selector(toggleImageVisibility))
        toggleButton.isEnabled = false
        navigationItem.rightBarButtonItem = toggleButton
    }

    private func setupUI() {
        view.addSubview(documentTypeLabel)
        view.addSubview(imagePreview)
        view.addSubview(keyValueTableView)
        imagePreview.addSubview(overlayView)

        documentTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        keyValueTableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            documentTypeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            documentTypeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            documentTypeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            imagePreview.topAnchor.constraint(equalTo: documentTypeLabel.bottomAnchor, constant: 16),
            imagePreview.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imagePreview.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imagePreview.heightAnchor.constraint(equalToConstant: 250),

            overlayView.topAnchor.constraint(equalTo: imagePreview.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imagePreview.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: imagePreview.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imagePreview.trailingAnchor),

            keyValueTableView.topAnchor.constraint(equalTo: imagePreview.bottomAnchor, constant: 16),
            keyValueTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            keyValueTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            keyValueTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            keyValueTableView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200)
        ])
    }


    @objc private func toggleImageVisibility() {
        isImageVisible.toggle()
        if isImageVisible {
            imagePreview.image = currentImage
            navigationItem.rightBarButtonItem?.title = "Hide Image"
        } else {
            imagePreview.image = nil
            navigationItem.rightBarButtonItem?.title = "Show Image"
        }
    }

    private func updateOverlayFrame(for image: UIImage) {
        let imageSize = image.size
        let imageViewSize = imagePreview.bounds.size
        let rect = AVMakeRect(aspectRatio: imageSize, insideRect: CGRect(origin: .zero, size: imageViewSize))
        overlayView.frame = rect
    }

    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let rectangleRequest = VNDetectRectanglesRequest { [weak self] request, _ in
            guard let self = self else { return }
            if let rect = request.results?.first as? VNRectangleObservation {
                DispatchQueue.main.async {
                    self.overlayView.drawBoundingBox(for: rect.boundingBox, color: .green, lineWidth: 2.0)
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
        print("Running OCR in region: \(detectTextRequest.regionOfInterest)")
        detectTextRequest.regionOfInterest = regionOfInterest ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .right, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([self.detectTextRequest])
        }
    }

    private func handleTextRecognition(request: VNRequest?, error: Error?) {
        guard error == nil, let results = request?.results as? [VNRecognizedTextObservation] else {
            print("OCR error or no results.")
            return
        }

        let recognizedWords = results.compactMap { obs -> RecognizedWord? in
            guard let text = obs.topCandidates(1).first?.string else { return nil }
            return RecognizedWord(text: text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), boundingBox: obs.boundingBox)
        }

        let mrzLines = MRZProcessor.detectMRZLines(from: recognizedWords)
        if let mrzLines = MRZProcessor.detectAndPrintMRZ(from: recognizedWords),
           MRZProcessor.isLikelyMRZBlock(mrzLines) {
            
            detectedDocumentType = "Passport (MRZ)"
            let lineTexts = mrzLines.map { $0.text }
            
            if let parsed = PassportMRZParser.parse(lines: lineTexts) {
                let keyValuePairs = [
                    RecognizedKeyValue(key: "SURNAME", keyTextObservation: nil, value: parsed.surname, valueTextObservation: nil),
                    // ... other fields ...
                ]
                
                DispatchQueue.main.async {
                    self.documentTypeLabel.text = "Detected: Passport"
                    self.recognizedKeyValuePairs = keyValuePairs
                }
            }
        }


        let useMRZ = MRZProcessor.isLikelyMRZBlock(mrzLines)

        var keyValuePairs: [RecognizedKeyValue] = []

        if useMRZ {
            detectedDocumentType = "Passport (MRZ)"
            let lineTexts = mrzLines.map { $0.text }
            if let parsed = PassportMRZParser.parse(lines: lineTexts) {
                keyValuePairs = [
                    RecognizedKeyValue(key: "SURNAME", keyTextObservation: nil, value: parsed.surname, valueTextObservation: nil),
                    RecognizedKeyValue(key: "GIVEN NAMES", keyTextObservation: nil, value: parsed.givenNames, valueTextObservation: nil),
                    RecognizedKeyValue(key: "PASSPORT NO", keyTextObservation: nil, value: parsed.passportNumber, valueTextObservation: nil),
                    RecognizedKeyValue(key: "DATE OF BIRTH", keyTextObservation: nil, value: parsed.dateOfBirth, valueTextObservation: nil),
                    RecognizedKeyValue(key: "NATIONALITY", keyTextObservation: nil, value: parsed.nationality, valueTextObservation: nil),
                    RecognizedKeyValue(key: "SEX", keyTextObservation: nil, value: parsed.sex, valueTextObservation: nil),
                    RecognizedKeyValue(key: "DATE OF EXPIRY", keyTextObservation: nil, value: parsed.expirationDate, valueTextObservation: nil)
                ]
            }
        } else {
            detectedDocumentType = "ID Card"
            keyValuePairs = IDCardFieldExtractor.extractKeyValuePairs(from: results)
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.overlayView.clear()
            results.forEach { self.overlayView.drawBoundingBox(for: $0) }
            self.documentTypeLabel.text = "Detected: \(self.detectedDocumentType ?? "Unknown")"
            self.recognizedKeyValuePairs = keyValuePairs
            self.keyValueTableView.isHidden = keyValuePairs.isEmpty
            print("Reloading table with \(self.recognizedKeyValuePairs.count) rows")
            self.keyValueTableView.reloadData()
        }
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recognizedKeyValuePairs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: KeyValueTableViewCell.identifier,
                                                       for: indexPath) as? KeyValueTableViewCell else {
            return UITableViewCell()
        }
        let pair = recognizedKeyValuePairs[indexPath.row]
        cell.configure(key: pair.key, value: pair.value ?? "")
        return cell
    }
}

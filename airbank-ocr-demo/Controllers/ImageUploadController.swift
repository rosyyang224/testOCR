//
//  ImageUploadController.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

import UIKit
import Vision
import Photos
import StringMetric

class ImageUploadController: UIViewController,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate,
                             UITableViewDelegate {


    private let imagePicker = UIImagePickerController()
    private let overlayView = TextOverlayView()
    private var recognizedKeyValuePairs: [RecognizedKeyValue] = []
    private var currentImage: UIImage?
    private var isImageVisible: Bool = true
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

    private lazy var documentTypeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .systemBlue
        return label
    }()

    private func updateOverlayFrame(for image: UIImage) {
        let imageSize = image.size
        let imageViewSize = imagePreview.bounds.size
        let rect = AVMakeRect(aspectRatio: imageSize, insideRect: CGRect(origin: .zero, size: imageViewSize))
        overlayView.frame = rect
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let image = currentImage, isImageVisible {
            updateOverlayFrame(for: image)
        }
    }

    private lazy var uploadButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Upload Photo", for: .normal)
        button.addTarget(self, action: #selector(showPickerOptions), for: .touchUpInside)
        return button
    }()

    private lazy var keyValueTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(KeyValueTableViewCell.self, forCellReuseIdentifier: "KeyValueCell")
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
        imagePicker.delegate = self
        setupUI()
        setupNavBar()
    }

    private func setupUI() {
        let stackView = UIStackView(arrangedSubviews: [documentTypeLabel, imagePreview, keyValueTableView, uploadButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false

        imagePreview.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        let flexibleHeightConstraint = imagePreview.heightAnchor.constraint(equalTo: imagePreview.widthAnchor, multiplier: 1.5)
        flexibleHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            flexibleHeightConstraint,
            imagePreview.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            imagePreview.heightAnchor.constraint(lessThanOrEqualToConstant: 300),
            overlayView.topAnchor.constraint(equalTo: imagePreview.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imagePreview.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: imagePreview.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imagePreview.trailingAnchor),
            uploadButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        imagePreview.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        keyValueTableView.setContentCompressionResistancePriority(.required, for: .vertical)
        uploadButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func setupNavBar() {
        let toggleButton = UIBarButtonItem(title: "Hide Image", style: .plain, target: self, action: #selector(toggleImageVisibility))
        toggleButton.isEnabled = false
        navigationItem.rightBarButtonItem = toggleButton
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

    @objc private func showPickerOptions() {
        let alert = UIAlertController(title: "Choose Source", message: nil, preferredStyle: .actionSheet)
        if let camera = pickerOption(for: .camera, title: "Take Photo") { alert.addAction(camera) }
        if let album = pickerOption(for: .savedPhotosAlbum, title: "Photo Album") { alert.addAction(album) }
        if let library = pickerOption(for: .photoLibrary, title: "Photo Library") { alert.addAction(library) }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if UIDevice.current.userInterfaceIdiom == .pad {
            alert.popoverPresentationController?.sourceView = view
            alert.popoverPresentationController?.sourceRect = view.bounds
        }
        present(alert, animated: true)
    }

    private func pickerOption(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else { return nil }
        return UIAlertAction(title: title, style: .default) { [weak self] _ in
            self?.imagePicker.sourceType = type
            self?.present(self!.imagePicker, animated: true)
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
            self.keyValueTableView.reloadData()
        }
    }

    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let rectangleRequest = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            if let rectObservation = request.results?.first as? VNRectangleObservation {
                print("Detected document rectangle")
                DispatchQueue.main.async {
                    self.overlayView.drawBoundingBox(for: rectObservation.boundingBox, color: .green, lineWidth: 2.0)
                }
                self.runOCR(on: cgImage, regionOfInterest: rectObservation.boundingBox)
            } else {
                print("No document detected — falling back to full image OCR")
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
}

// MARK: - UITableViewDataSource

extension ImageUploadController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recognizedKeyValuePairs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: KeyValueTableViewCell.identifier, for: indexPath) as? KeyValueTableViewCell else {
            return UITableViewCell()
        }
        let pair = recognizedKeyValuePairs[indexPath.row]
        cell.configure(key: pair.key, value: pair.value ?? "—")
        return cell
    }
}


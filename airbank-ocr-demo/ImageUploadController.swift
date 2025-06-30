import UIKit
import Vision
import Photos
import StringMetric


final class ImageUploadController: UIViewController {
    private let imagePicker = UIImagePickerController()
    private let overlayView = TextOverlayView()
    private var recognizedKeyValuePairs: [RecognizedKeyValue] = []
    private var currentImage: UIImage?
    private var isImageVisible: Bool = true

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
        let stackView = UIStackView(arrangedSubviews: [imagePreview, keyValueTableView, uploadButton])
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
        if let error = error {
            print("Recognition error: \(error.localizedDescription)")
            return
        }

        guard let results = request?.results as? [VNRecognizedTextObservation] else {
            print("No text recognized.")
            return
        }

       let recognizedTexts = results.compactMap { observation -> (text: String, boundingBox: CGRect)? in
           guard let text = observation.topCandidates(1).first?.string else { return nil }
           return (text: text, boundingBox: observation.boundingBox)
       }.sorted { first, second in
           if abs(first.boundingBox.origin.y - second.boundingBox.origin.y) > 0.05 {
               return first.boundingBox.origin.y > second.boundingBox.origin.y
           }
           return first.boundingBox.origin.x < second.boundingBox.origin.x
       }
        
        let keyValuePairs = extractKeyValuePairs(from: results)

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.overlayView.clear()
            results.forEach { self.overlayView.drawBoundingBox(for: $0) }

            self.recognizedKeyValuePairs = keyValuePairs
            self.keyValueTableView.isHidden = keyValuePairs.isEmpty
            self.keyValueTableView.reloadData()
        }



       DispatchQueue.main.async { [weak self] in
           self?.overlayView.clear()
           results.forEach { self?.overlayView.drawBoundingBox(for: $0) }
           
           self?.recognizedKeyValuePairs = keyValuePairs
           self?.keyValueTableView.isHidden = keyValuePairs.isEmpty
           self?.keyValueTableView.reloadData()
       }
   }
    
    private func extractKeyValuePairs(from observations: [VNRecognizedTextObservation]) -> [RecognizedKeyValue] {
        var results: [RecognizedKeyValue] = []

        let lines: [(text: String, box: CGRect, observation: VNRecognizedTextObservation)] = observations.compactMap {
            guard let text = $0.topCandidates(1).first?.string else { return nil }
            return (text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), $0.boundingBox, $0)
        }

        for (keyText, keyBox, keyObs) in lines {
            let normalizedKey = keyText.uppercased()

            guard let matchedElement = RecognizedKeyValue.DocumentElement.allCases.first(where: { element in
                element.keywords.contains(where: { keyword in
                    keyword.distance(between: normalizedKey) > 0.88
                })
            }) else {
                continue
            }


            let isHorizontal = keyText.contains("SURNAME") || keyText.contains("GIVEN") || keyText.contains("DOCUMENT")

            let candidates = lines.filter { candidate in
                candidate.observation != keyObs &&
                !RecognizedKeyValue.DocumentElement.allKeywords.contains(candidate.text)
            }

            let valueCandidate = candidates
                .filter { candidate in
                    if isHorizontal {
                        let sameRow = abs(candidate.box.midY - keyBox.midY) < 0.05
                        let rightOfKey = candidate.box.minX > keyBox.maxX
                        return sameRow && rightOfKey
                    } else {
                        let below = candidate.box.maxY < keyBox.minY
                        let alignedHorizontally = abs(candidate.box.midX - keyBox.midX) < 0.2
                        return below && alignedHorizontally
                    }
                }
                .min(by: { a, b in
                    let aDistance = hypot(a.box.midX - keyBox.midX, a.box.midY - keyBox.midY)
                    let bDistance = hypot(b.box.midX - keyBox.midX, b.box.midY - keyBox.midY)
                    return aDistance < bDistance
                })

            if let match = valueCandidate {
                results.append(
                    RecognizedKeyValue(
                        key: matchedElement.rawValue,
                        keyTextObservation: keyObs,
                        value: match.text,
                        valueTextObservation: match.observation
                    )
                )
            }
        }

        return results
    }


    private func processImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .right, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([self.detectTextRequest])
            } catch {
                print("Failed to perform OCR: \(error)")
            }
        }
    }
}

// MARK: - UITableView DataSource & Delegate
extension ImageUploadController: UITableViewDataSource, UITableViewDelegate {
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return recognizedKeyValuePairs.count
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "KeyValueCell", for: indexPath) as! KeyValueTableViewCell
    let pair = recognizedKeyValuePairs[indexPath.row]
    cell.configure(key: pair.key, value: pair.value ?? "")
    return cell
}

func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return recognizedKeyValuePairs.isEmpty ? nil : "Recognized Key-Value Pairs"
}
}

extension ImageUploadController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true)
}

func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    dismiss(animated: true)
    guard let image = info[.originalImage] as? UIImage else { return }

    navigationItem.rightBarButtonItem?.isEnabled = true
    currentImage = image
    imagePreview.image = image
    updateOverlayFrame(for: image)
    isImageVisible = true
    navigationItem.rightBarButtonItem?.title = "Hide Image"
    
    processImage(image)
}
}

// MARK: - Custom Table View Cell
class KeyValueTableViewCell: UITableViewCell {
private let keyLabel = UILabel()
private let valueLabel = UILabel()

override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
}

required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}

private func setupUI() {
    keyLabel.font = UIFont.boldSystemFont(ofSize: 14)
    keyLabel.textColor = .label
    keyLabel.numberOfLines = 0
    
    valueLabel.font = UIFont.systemFont(ofSize: 14)
    valueLabel.textColor = .secondaryLabel
    valueLabel.numberOfLines = 0
    
    let stackView = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
    stackView.axis = .horizontal
    stackView.spacing = 12
    stackView.alignment = .top
    stackView.distribution = .fill
    
    keyLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    keyLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    
    stackView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stackView)
    
    NSLayoutConstraint.activate([
        stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
        stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
        stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
    ])
}

func configure(key: String, value: String) {
    keyLabel.text = key
    valueLabel.text = value
}
}

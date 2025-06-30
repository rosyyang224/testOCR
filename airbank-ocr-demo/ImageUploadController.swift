import UIKit
import Vision
import Photos

final class ImageUploadController: UIViewController {
    private let imagePicker = UIImagePickerController()
    private let overlayView = TextOverlayView()

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

    private lazy var uploadButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("Upload Photo", for: .normal)
        button.addTarget(self, action: #selector(showPickerOptions), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        imagePicker.delegate = self
        setupUI()
        setupNavBar()
    }

    private func setupUI() {
        [imagePreview, overlayView, uploadButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            imagePreview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imagePreview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imagePreview.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imagePreview.heightAnchor.constraint(equalTo: imagePreview.widthAnchor, multiplier: 3/2),

            overlayView.topAnchor.constraint(equalTo: imagePreview.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imagePreview.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: imagePreview.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imagePreview.trailingAnchor),

            uploadButton.heightAnchor.constraint(equalToConstant: 50),
            uploadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            uploadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupNavBar() {
        let toggleButton = UIBarButtonItem(title: "Hide Image", style: .plain, target: self, action: #selector(toggleImageVisibility))
        toggleButton.isEnabled = false
        navigationItem.rightBarButtonItem = toggleButton
    }

    @objc private func toggleImageVisibility() {
        imagePreview.isHidden.toggle()
        navigationItem.rightBarButtonItem?.title = imagePreview.isHidden ? "Show Image" : "Hide Image"
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

        DispatchQueue.main.async { [weak self] in
            self?.overlayView.clear()
            results.forEach { self?.overlayView.drawBoundingBox(for: $0) }
        }
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

extension ImageUploadController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }

        navigationItem.rightBarButtonItem?.isEnabled = true
        imagePreview.image = image
        processImage(image)
    }
}

import UIKit

final class HomeViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerView = HomeHeaderView()
    private let mainCardView = HomeMainCardView()
    private let quickActionsView = HomeQuickActionsView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.backgroundColor
        setupUI()
        setupConstraints()
        setupActions()
        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInsetAdjustmentBehavior = .automatic
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hides nav bar for clean Home screen; DocumentResultController will unhide it
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.clipsToBounds = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [headerView, mainCardView, quickActionsView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            // Main Card
            mainCardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            mainCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            // Quick Actions
            quickActionsView.topAnchor.constraint(equalTo: mainCardView.bottomAnchor, constant: 20),
            quickActionsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            quickActionsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            quickActionsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func setupActions() {
        mainCardView.primaryScanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)
        quickActionsView.historyButton.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func scanTapped() {
        presentPickerOptions()
    }

    @objc private func historyTapped() {
        print("View History tapped")
        // TODO: Push history screen
    }
}

// MARK: - UIImagePickerControllerDelegate

extension HomeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func presentPickerOptions() {
        let picker = UIImagePickerController()
        picker.delegate = self

        let alert = UIAlertController(title: "Choose Source", message: nil, preferredStyle: .actionSheet)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
                picker.sourceType = .camera
                self.present(picker, animated: true)
            })
        }

        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
                picker.sourceType = .photoLibrary
                self.present(picker, animated: true)
            })
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Required for iPad to avoid crash
        if let popover = alert.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(alert, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }

        let controller = DocumentResultViewController()
        controller.loadImage(image)
        navigationController?.pushViewController(controller, animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

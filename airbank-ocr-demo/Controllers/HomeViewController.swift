//  HomeViewController.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.

import UIKit

final class HomeViewController: UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let headerView = HomeHeaderView()
    private let mainCardView = HomeMainCardView()
    private let quickActionsView = HomeQuickActionsView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    private func setupUI() {
        view.backgroundColor = AppTheme.backgroundColor

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
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView constraints
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // HeaderView
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            // MainCardView
            mainCardView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 32),
            mainCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            mainCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            // QuickActionsView
            quickActionsView.topAnchor.constraint(equalTo: mainCardView.bottomAnchor, constant: 20),
            quickActionsView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            quickActionsView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            quickActionsView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    private func setupActions() {
        mainCardView.primaryScanButton.addTarget(self, action: #selector(scanTapped), for: .touchUpInside)
        quickActionsView.uploadButton.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        quickActionsView.historyButton.addTarget(self, action: #selector(historyTapped), for: .touchUpInside)
    }

    @objc private func scanTapped() {
        let scanVC = ImageUploadController()
        navigationController?.pushViewController(scanVC, animated: true)
    }

    @objc private func uploadTapped() {
        print("Upload from Gallery tapped")
    }

    @objc private func historyTapped() {
        print("View History tapped")
    }
}

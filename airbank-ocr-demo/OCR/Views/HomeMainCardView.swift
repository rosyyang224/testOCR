//
//  HomeMainCardView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//

import UIKit

final class HomeMainCardView: UIView {

    // MARK: - Subviews

    private let passportIllustrationView = UIView()
    private let scanInstructionLabel = UILabel()
    public let primaryScanButton = UIButton(type: .system)

    // MARK: - Exposed Button for Action Assignment

    public var scanButton: UIButton {
        return primaryScanButton
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        AppTheme.styleCardView(self)

        passportIllustrationView.translatesAutoresizingMaskIntoConstraints = false
        passportIllustrationView.backgroundColor = AppTheme.lightGray
        passportIllustrationView.layer.cornerRadius = 16
        passportIllustrationView.layer.masksToBounds = true
        addSubview(passportIllustrationView)

        // Add illustration inside
        createPassportIllustration(in: passportIllustrationView)

        scanInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
        scanInstructionLabel.text = "Scan or upload your passport to extract information automatically"
        scanInstructionLabel.font = AppTheme.subtitleFont
        scanInstructionLabel.textColor = AppTheme.primaryText
        scanInstructionLabel.textAlignment = .center
        scanInstructionLabel.numberOfLines = 0
        addSubview(scanInstructionLabel)

        primaryScanButton.translatesAutoresizingMaskIntoConstraints = false
        primaryScanButton.setTitle("Scan Passport", for: .normal)
        AppTheme.stylePrimaryButton(primaryScanButton)
        addSubview(primaryScanButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            passportIllustrationView.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            passportIllustrationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            passportIllustrationView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            passportIllustrationView.heightAnchor.constraint(equalToConstant: 200),

            scanInstructionLabel.topAnchor.constraint(equalTo: passportIllustrationView.bottomAnchor, constant: 20),
            scanInstructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            scanInstructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),

            primaryScanButton.topAnchor.constraint(equalTo: scanInstructionLabel.bottomAnchor, constant: 24),
            primaryScanButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            primaryScanButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            primaryScanButton.heightAnchor.constraint(equalToConstant: 56),
            primaryScanButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Drawing

    private func createPassportIllustration(in container: UIView) {
        let passportView = UIView()
        passportView.translatesAutoresizingMaskIntoConstraints = false
        passportView.backgroundColor = AppTheme.darkBlue
        passportView.layer.cornerRadius = 8
        passportView.layer.masksToBounds = true
        container.addSubview(passportView)

        let coverLabel = UILabel()
        coverLabel.translatesAutoresizingMaskIntoConstraints = false
        coverLabel.text = "PASSPORT"
        coverLabel.font = UIFont.boldSystemFont(ofSize: 16)
        coverLabel.textColor = .white
        coverLabel.textAlignment = .center
        passportView.addSubview(coverLabel)

        let emblemView = UIView()
        emblemView.translatesAutoresizingMaskIntoConstraints = false
        emblemView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        emblemView.layer.cornerRadius = 20
        passportView.addSubview(emblemView)

        NSLayoutConstraint.activate([
            passportView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            passportView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            passportView.widthAnchor.constraint(equalToConstant: 200),
            passportView.heightAnchor.constraint(equalToConstant: 140),

            emblemView.centerXAnchor.constraint(equalTo: passportView.centerXAnchor),
            emblemView.topAnchor.constraint(equalTo: passportView.topAnchor, constant: 20),
            emblemView.widthAnchor.constraint(equalToConstant: 40),
            emblemView.heightAnchor.constraint(equalToConstant: 40),

            coverLabel.centerXAnchor.constraint(equalTo: passportView.centerXAnchor),
            coverLabel.bottomAnchor.constraint(equalTo: passportView.bottomAnchor, constant: -20)
        ])
    }
}

//
//  ResultCardView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import UIKit

final class ResultCardView: UIView {

    let documentTypeLabel = DocumentResultHeader()
    let imagePreview = UIImageView()
    let overlayView = TextOverlayView()
    let tableView = UITableView()
    
    var tableHeightConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
        setupStack()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCard() {
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.05
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 10
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupStack() {
        imagePreview.contentMode = .scaleAspectFit
        imagePreview.layer.cornerRadius = 12
        imagePreview.clipsToBounds = true
        imagePreview.backgroundColor = .secondarySystemBackground
        imagePreview.translatesAutoresizingMaskIntoConstraints = false
        imagePreview.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false

        tableView.register(KeyValueTableViewCell.self, forCellReuseIdentifier: KeyValueTableViewCell.identifier)
        tableView.layer.cornerRadius = 12
        tableView.isHidden = true
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [documentTypeLabel, imagePreview, tableView])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            imagePreview.heightAnchor.constraint(equalToConstant: 250),
            overlayView.topAnchor.constraint(equalTo: imagePreview.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imagePreview.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: imagePreview.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imagePreview.trailingAnchor),

            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
        
        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
        tableHeightConstraint.isActive = true

    }
}

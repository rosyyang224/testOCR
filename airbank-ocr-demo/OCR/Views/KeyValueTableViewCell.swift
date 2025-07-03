//
//  KeyValueTableViewCell.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//

import UIKit

class KeyValueTableViewCell: UITableViewCell {
    static let identifier = "KeyValueTableViewCell"

    let keyLabel = UILabel()
    let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        keyLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.textAlignment = .right

        let stack = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8

        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(key: String, value: String) {
        keyLabel.text = key
        valueLabel.text = value
    }
}

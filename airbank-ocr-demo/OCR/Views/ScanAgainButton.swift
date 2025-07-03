//
//  ScanAgainButton.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//


import UIKit

final class ScanAgainButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setTitle("Scan Another", for: .normal)
        backgroundColor = AppTheme.primaryColor
        setTitleColor(.white, for: .normal)
        layer.cornerRadius = 12
        titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

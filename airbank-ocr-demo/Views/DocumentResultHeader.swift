//
//  DocumentResultHeader.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/2/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import UIKit

final class DocumentResultHeader: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        font = UIFont.systemFont(ofSize: 24, weight: .bold)
        textAlignment = .center
        textColor = .label
        numberOfLines = 2
        lineBreakMode = .byTruncatingTail
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .vertical)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//
//  HomeQuickActionsView.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//

import UIKit

final class HomeQuickActionsView: UIStackView {
    let historyButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .horizontal
        spacing = 12
        distribution = .fillEqually
        setupButtons()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupButtons() {
        historyButton.setTitle("Recent Scans", for: .normal)
        AppTheme.styleSecondaryButton(historyButton)
        addArrangedSubview(historyButton)
    }
}

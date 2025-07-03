//
//  DocumentPreviewViewController.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/3/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


final class DocumentPreviewViewController: UIViewController {
    
    init(image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }
}

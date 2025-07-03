// DocumentPickerDelegate.swift
// SwiftUI-compatible document picker for iOS

// DocumentPickerDelegate.swift
// SwiftUI-compatible document picker for iOS

import UIKit

final class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate, ObservableObject {
    var onPick: ((URL) -> Void)?

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        onPick?(url)
    }
}

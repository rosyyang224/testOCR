// PDFSelector.swift
import Foundation
import SwiftUI
import UniformTypeIdentifiers
import UIKit

enum PDFSelector {
    static func pick() async throws -> URL? {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        let delegate = DocumentPickerDelegate()

        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.windows.first?.rootViewController?.present(picker, animated: true)

        picker.delegate = delegate
        return await withCheckedContinuation { continuation in
            delegate.completion = { url in
                continuation.resume(returning: url)
            }
        }
    }
}

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    var completion: ((URL?) -> Void)?

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completion?(urls.first)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion?(nil)
    }
}
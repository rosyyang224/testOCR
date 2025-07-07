import PythonKit
import Foundation

enum PDFTextExtractionMethod {
    case docling
    case pypdf
}

enum TextExtractor {
    static func extractText(from url: URL, using method: PDFTextExtractionMethod) throws -> String {
        print("Starting text extraction for: \(url.path)")
        print("Using method: \(method == .docling ? "docling" : "pypdf")")

        let sys = Python.import("sys")

        // Handle PYTHONPATH
        if let pythonPath = ProcessInfo.processInfo.environment["PYTHONPATH"] {
            let pathAlreadyIncluded = Array(sys.path).map { String($0) }.contains(pythonPath)
            if !pathAlreadyIncluded {
                print("Adding PYTHONPATH to sys.path: \(pythonPath)")
                sys.path.insert(0, pythonPath)
            }
        }

        // Add script directory if needed
        let scriptDir = Bundle.main.resourcePath!
        let pathAlreadyHasScriptDir = Array(sys.path).map { String($0) }.contains(scriptDir)
        if !pathAlreadyHasScriptDir {
            print("Adding script directory to sys.path: \(scriptDir)")
            sys.path.insert(1, scriptDir)
        }

        print("Final sys.path: \(sys.path)")

        // Try to import the Python script
        print("Importing pdf_extractor module...")
        let extractor = Python.import("pdf_extractor")

        let methodName = method == .docling ? "docling" : "pypdf"
        print("Extracting text using method: \(methodName)...")
        let rawText = extractor.extract_text(url.path, method: methodName)

        print("Extraction complete. Characters extracted: \(String(rawText)?.count ?? 0)")

        return String(rawText) ?? ""
    }
}

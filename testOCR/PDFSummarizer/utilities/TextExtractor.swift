import PythonKit
import Foundation

enum PDFTextExtractionMethod {
    case docling
    case pypdf
}

enum TextExtractor {
    static func extractTextPages(from url: URL, using method: PDFTextExtractionMethod) throws -> [String] {
        print("📝 Starting text extraction for: \(url.path)")
        print("📄 Using method: \(method == .docling ? "docling" : "pypdf")")

        let sys = Python.import("sys")

        // Handle PYTHONPATH
        if let pythonPath = ProcessInfo.processInfo.environment["PYTHONPATH"] {
            if !Array(sys.path).map({ String($0) }).contains(pythonPath) {
                print("➕ Adding PYTHONPATH to sys.path: \(pythonPath)")
                sys.path.insert(0, pythonPath)
            }
        }

        let scriptDir = Bundle.main.resourcePath!
        if !Array(sys.path).map({ String($0) }).contains(scriptDir) {
            print("➕ Adding script directory to sys.path: \(scriptDir)")
            sys.path.insert(1, scriptDir)
        }

        print("🐍 Final sys.path: \(sys.path)")

        print("📦 Importing pdf_extractor module...")
        let extractor = Python.import("pdf_extractor")

        let methodName = method == .docling ? "docling" : "pypdf"
        print("🚀 Extracting text using method: \(methodName)...")
        let rawText = extractor.extract_text(url.path, method: methodName)

        let text = String(rawText) ?? ""
        print("✅ Extraction complete. Characters extracted: \(text.count)")

        return text.components(separatedBy: "\n---PAGE_BREAK---\n")
    }
}

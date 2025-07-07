import PDFKit
import CoreGraphics

struct PDFPageRenderer {
    static func renderPageCGImages(from url: URL, dpi: CGFloat = 144) -> [CGImage] {
        guard let document = PDFDocument(url: url) else { return [] }

        return (0..<document.pageCount).compactMap { index in
            guard let page = document.page(at: index), let pageRef = page.pageRef else { return nil }

            let pageRect = pageRef.getBoxRect(.mediaBox)
            let scale = dpi / 72.0
            let width = Int(pageRect.width * scale)
            let height = Int(pageRect.height * scale)

            guard let context = CGContext(data: nil,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: 0,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return nil }

            // Flip coordinate system for correct orientation
            context.saveGState()
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1.0, y: -1.0)

            // Scale and render PDF page
            context.scaleBy(x: scale, y: scale)
            context.drawPDFPage(pageRef)
            context.restoreGState()

            return context.makeImage()
        }
    }
}

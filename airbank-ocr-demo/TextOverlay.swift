import UIKit
import Vision

final class TextOverlayView: UIView {
    private var layers = [CAShapeLayer]()

    func drawBoundingBox(for observation: VNRecognizedTextObservation) {
        let imageRect = bounds

        let rect = CGRect(
            x: observation.boundingBox.minX * imageRect.width,
            y: (1 - observation.boundingBox.maxY) * imageRect.height,
            width: observation.boundingBox.width * imageRect.width,
            height: observation.boundingBox.height * imageRect.height
        )

        let shape = CAShapeLayer()
        shape.frame = rect
        shape.borderColor = UIColor.yellow.cgColor
        shape.borderWidth = 2
        shape.opacity = 0.75
        shape.cornerRadius = 6
        layer.addSublayer(shape)
        layers.append(shape)

        if let text = observation.topCandidates(1).first?.string {
            let label = UILabel(frame: rect)
            label.text = text
            label.textColor = .red
            label.font = .systemFont(ofSize: 5)
            addSubview(label)
        }
    }

    func clear() {
        layers.forEach { $0.removeFromSuperlayer() }
        layers.removeAll()
        subviews.forEach { $0.removeFromSuperview() }
    }
}

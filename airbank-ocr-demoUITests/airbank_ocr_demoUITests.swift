import XCTest
@testable import airbank_ocr_demo
import Vision
import CoreGraphics

final class DocumentMatchingTests: XCTestCase {

    private var controller: ImageUploadController!

    override func setUp() {
        super.setUp()
        controller = ImageUploadController()
    }

    override func tearDown() {
        controller = nil
        super.tearDown()
    }

    func testKeyValueExtractionFromMockData() {
        let pairs = controller.extractKeyValuePairs(from: observations as [any TextObservationRepresentable])


        for pair in pairs {
            print("🔍 \(pair.key) → \(pair.value ?? "nil")")
        }

        XCTAssertTrue(pairs.contains { $0.key == "Date of exp" && $0.value == "02/24/2033" })
        XCTAssertTrue(pairs.contains { $0.key == "Date of issue" && $0.value == "05/11/2025" })
        XCTAssertTrue(pairs.contains { $0.key == "Date of birth" && $0.value == "02/24/2004" })
        XCTAssertTrue(pairs.contains { $0.key == "Family name" && $0.value == "YANG" })
        XCTAssertTrue(pairs.contains { $0.key == "Given names" && $0.value == "ROSEMARY ELAINE" })
    }
}

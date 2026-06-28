import XCTest
@testable import AnimateDex

final class SequenceDetectionTests: XCTestCase {
    func testNaturalOrderingAndMissingNumbers() {
        let service = SequenceDetectionService()
        let results = [
            sample("image10.png", number: 10),
            sample("image1.png", number: 1),
            sample("image2.png", number: 2)
        ]

        let output = service.detect(results: results)
        XCTAssertEqual(output.orderedResults.map(\.filename), ["image1.png", "image2.png", "image10.png"])
        XCTAssertFalse(output.issues.isEmpty)
    }

    private func sample(_ name: String, number: Int?) -> ImageInspectionResult {
        ImageInspectionResult(
            fileURL: URL(fileURLWithPath: "/tmp/\(name)"),
            filename: name,
            fileExtension: "png",
            fileSizeBytes: 1,
            width: 100,
            height: 100,
            orientation: .up,
            readable: true,
            explicitSequenceNumber: number,
            sequenceCandidates: number.map { [$0] } ?? []
        )
    }
}

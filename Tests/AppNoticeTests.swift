import XCTest
@testable import AnimateDex

final class AppNoticeTests: XCTestCase {
    func testCopyTextIncludesPathAndSuggestion() {
        let notice = AppNotice(
            kind: .error,
            title: "Import failed",
            summary: "No usable images",
            details: "The selected folder did not contain supported files.",
            path: "/tmp/example.animdex",
            suggestion: "Choose a folder with PNG, JPG, JPEG, or WEBP files."
        )

        let copyText = notice.copyText
        XCTAssertTrue(copyText.contains("Title: Import failed"))
        XCTAssertTrue(copyText.contains("Summary: No usable images"))
        XCTAssertTrue(copyText.contains("Details: The selected folder did not contain supported files."))
        XCTAssertTrue(copyText.contains("Path: /tmp/example.animdex"))
        XCTAssertTrue(copyText.contains("Next step: Choose a folder with PNG, JPG, JPEG, or WEBP files."))
        XCTAssertTrue(copyText.contains("Severity: error"))
    }
}

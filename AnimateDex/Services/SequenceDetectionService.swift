import Foundation

struct SequenceDetectionResult: Sendable {
    let orderedResults: [ImageInspectionResult]
    let issues: [ValidationIssue]
}

struct SequenceDetectionService {
    func detect(results: [ImageInspectionResult]) -> SequenceDetectionResult {
        let sorted = results.enumerated().sorted { lhs, rhs in
            let left = lhs.element
            let right = rhs.element

            switch (left.explicitSequenceNumber, right.explicitSequenceNumber) {
            case let (l?, r?) where l != r:
                return l < r
            case (.some, .none):
                return true
            case (.none, .some):
                return false
            default:
                if NaturalSort.compare(left.filename, right.filename) {
                    return true
                }
                if NaturalSort.compare(right.filename, left.filename) {
                    return false
                }
                return lhs.offset < rhs.offset
            }
        }.map(\.element)

        var issues: [ValidationIssue] = []
        let numericResults = sorted.compactMap { $0.explicitSequenceNumber }
        if let minValue = numericResults.min(), let maxValue = numericResults.max(), numericResults.count > 1 {
            let counts = Dictionary(grouping: numericResults, by: { $0 })
            let duplicates = counts.filter { $0.value.count > 1 }.map(\.key).sorted()
            if !duplicates.isEmpty {
                issues.append(
                    ValidationIssue(
                        severity: .warning,
                        code: "duplicate_sequence_numbers",
                        message: "Duplicate sequence numbers detected: \(duplicates.map(String.init).joined(separator: ", "))"
                    )
                )
            }

            let expected = Set(minValue...maxValue)
            let actual = Set(numericResults)
            let missing = expected.subtracting(actual).sorted()
            if !missing.isEmpty {
                issues.append(
                    ValidationIssue(
                        severity: .warning,
                        code: "missing_sequence_numbers",
                        message: "Missing sequence numbers: \(missing.map(String.init).joined(separator: ", "))"
                    )
                )
            }

            if duplicates.isEmpty && missing.isEmpty && numericResults != numericResults.sorted() {
                issues.append(
                    ValidationIssue(
                        severity: .info,
                        code: "irregular_numbering",
                        message: "Sequence numbers exist but do not form a clean run."
                    )
                )
            }
        }

        return SequenceDetectionResult(orderedResults: sorted, issues: issues)
    }
}

import Foundation

struct ValidationIssue: Codable, Identifiable, Sendable, Equatable {
    var id: String
    var severity: ValidationSeverity
    var code: String
    var message: String
    var relatedPath: String?

    init(
        id: String = UUID().uuidString,
        severity: ValidationSeverity,
        code: String,
        message: String,
        relatedPath: String? = nil
    ) {
        self.id = id
        self.severity = severity
        self.code = code
        self.message = message
        self.relatedPath = relatedPath
    }
}

enum ValidationSeverity: String, Codable, Sendable, CaseIterable {
    case info
    case warning
    case error
}

struct ImportReport: Codable, Sendable, Equatable {
    var schemaVersion: Int = 1
    var sourceKind: SourceKind
    var sourcePath: String
    var supportedFileCount: Int
    var unsupportedFiles: [String]
    var unreadableFiles: [String]
    var dominantSize: String?
    var dominantOrientation: ImageOrientation
    var issues: [ValidationIssue]
    var importedAt: Date
}

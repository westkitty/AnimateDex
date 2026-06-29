import Foundation

enum MotionRecipeValidationSeverity: String, Codable, Sendable {
    case error
    case warning
    case info
}

struct MotionRecipeValidationIssue: Codable, Identifiable, Sendable, Equatable {
    var id: String = UUID().uuidString
    var severity: MotionRecipeValidationSeverity
    var code: String
    var message: String
}

struct MotionRecipeValidationResult: Sendable, Equatable {
    var recipe: MotionRecipe?
    var issues: [MotionRecipeValidationIssue]
    var ignoredFields: [String] = []

    var hasErrors: Bool {
        issues.contains(where: { $0.severity == .error })
    }

    var hasWarnings: Bool {
        issues.contains(where: { $0.severity == .warning })
    }

    var hasInfo: Bool {
        issues.contains(where: { $0.severity == .info })
    }
}

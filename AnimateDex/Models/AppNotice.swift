import Foundation

struct AppNotice: Sendable, Equatable {
    enum Kind: String, Sendable, Equatable {
        case info
        case warning
        case error
    }

    var kind: Kind
    var title: String
    var summary: String
    var details: String
    var path: String?
    var suggestion: String?

    var copyText: String {
        var lines: [String] = []
        lines.append("Title: \(title)")
        lines.append("Summary: \(summary)")
        lines.append("Details: \(details)")
        if let path, !path.isEmpty {
            lines.append("Path: \(path)")
        }
        if let suggestion, !suggestion.isEmpty {
            lines.append("Next step: \(suggestion)")
        }
        lines.append("Severity: \(kind.rawValue)")
        return lines.joined(separator: "\n")
    }
}

enum AppWorkflowSection: String, CaseIterable, Identifiable, Sendable {
    case overview
    case sequence
    case motionRecipe
    case render
    case diagnostics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .sequence: "Sequence"
        case .motionRecipe: "Motion Recipe"
        case .render: "Render"
        case .diagnostics: "Logs / Diagnostics"
        }
    }

    var symbolName: String {
        switch self {
        case .overview: "square.grid.2x2"
        case .sequence: "film.stack"
        case .motionRecipe: "wand.and.stars"
        case .render: "play.rectangle"
        case .diagnostics: "exclamationmark.bubble"
        }
    }
}

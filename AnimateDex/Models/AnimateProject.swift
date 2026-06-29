import Foundation

struct AnimateProject: Codable, Sendable, Equatable {
    var schemaVersion: Int = 1
    var projectName: String
    var createdAt: Date
    var updatedAt: Date
    var sourceKind: SourceKind
    var sourcePath: String
    var workspacePath: String
    var scenePlanPath: String
    var renderSettings: RenderSettings
    var lastMotionRecipeName: String? = nil

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case projectName
        case createdAt
        case updatedAt
        case sourceKind
        case sourcePath
        case workspacePath
        case scenePlanPath
        case renderSettings
        case lastMotionRecipeName
    }
}

enum SourceKind: String, Codable, Sendable, CaseIterable {
    case folder
    case zip
    case unknown
}

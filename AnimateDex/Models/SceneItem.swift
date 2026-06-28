import Foundation

struct SceneItem: Codable, Identifiable, Sendable, Equatable {
    var id: String
    var sequenceIndex: Int
    var filename: String
    var sourcePath: String
    var workingPath: String
    var width: Int
    var height: Int
    var fileSizeBytes: Int64
    var durationSeconds: Double
    var motionPreset: MotionPreset
    var transitionIn: String
    var transitionOut: String
    var caption: String
    var notes: String
    var validationStatus: String
    var validationIssues: [ValidationIssue]
    var fileExtension: String
    var orientation: ImageOrientation
    var dominantProjectSize: String?
    var differsFromDominantSize: Bool
    var readable: Bool
    var explicitSequenceNumber: Int?
    var importOrder: Int
}

enum ImageOrientation: String, Codable, Sendable, CaseIterable {
    case up
    case upMirrored
    case down
    case downMirrored
    case left
    case leftMirrored
    case right
    case rightMirrored
    case unknown
}

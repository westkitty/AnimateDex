import Foundation

struct MotionRecipePreview: Sendable, Equatable {
    var recipeName: String
    var description: String
    var totalScenes: Int
    var affectedSceneCount: Int
    var globalRenderSettingChanges: [String]
    var sectionCount: Int
    var overrideCount: Int
    var durationChangesCount: Int
    var motionPresetChangesCount: Int
    var transitionChangesCount: Int
    var validationIssues: [MotionRecipeValidationIssue]
    var affectedScenes: [MotionRecipePreviewSceneChange]
}

struct MotionRecipePreviewSceneChange: Sendable, Equatable, Identifiable {
    var id: String { "scene-\(sequenceIndex)" }

    var sequenceIndex: Int
    var filename: String
    var beforeDuration: Double
    var afterDuration: Double
    var beforeMotionPreset: MotionPreset
    var afterMotionPreset: MotionPreset
    var beforeTransitionIn: String
    var afterTransitionIn: String
    var beforeTransitionOut: String
    var afterTransitionOut: String
}

struct MotionRecipeApplicationResult: Sendable, Equatable {
    var recipeName: String
    var affectedSceneCount: Int
    var changedSceneCount: Int
    var backupPath: String
    var appliedRecipePath: String
    var reportPath: String
    var outputScenePlanPath: String
    var warnings: [String]
    var ignoredFields: [String]
}

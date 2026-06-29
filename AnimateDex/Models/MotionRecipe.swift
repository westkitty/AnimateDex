import Foundation

struct MotionRecipe: Codable, Sendable, Equatable {
    var schemaVersion: Int
    var recipeName: String
    var description: String
    var target: MotionRecipeTarget
    var globalRenderSettings: MotionRecipeGlobalRenderSettings
    var globalDefaults: MotionRecipeGlobalDefaults
    var sections: [MotionRecipeSection]
    var sceneOverrides: [MotionRecipeSceneOverride]
}

struct MotionRecipeTarget: Codable, Sendable, Equatable {
    var matchMode: String
    var sceneRange: MotionRecipeSceneRange
}

struct MotionRecipeSceneRange: Codable, Sendable, Equatable {
    var start: Int
    var end: Int
}

struct MotionRecipeGlobalRenderSettings: Codable, Sendable, Equatable {
    var outputWidth: Int
    var outputHeight: Int
    var fps: Int
    var defaultSceneDuration: Double
}

struct MotionRecipeGlobalDefaults: Codable, Sendable, Equatable {
    var durationSeconds: Double
    var motionPreset: MotionPreset
    var transitionIn: String
    var transitionOut: String
}

struct MotionRecipeSection: Codable, Sendable, Equatable, Identifiable {
    var id: String { name }
    var name: String
    var sceneRange: MotionRecipeSceneRange
    var durationSeconds: Double
    var motionPreset: MotionPreset
    var transitionIn: String
    var transitionOut: String
    var notes: String
}

struct MotionRecipeSceneOverride: Codable, Sendable, Equatable, Identifiable {
    var id: String { overrideKey }

    var sequenceIndex: Int
    var durationSeconds: Double
    var motionPreset: MotionPreset
    var transitionIn: String
    var transitionOut: String
    var notes: String
    var sceneId: String?
    var filenameContains: String?

    private var overrideKey: String {
        "scene-\(sequenceIndex)"
    }
}

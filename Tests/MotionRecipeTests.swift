import XCTest
@testable import AnimateDex

final class MotionRecipeTests: XCTestCase {
    func testExampleRecipesValidateSuccessfully() throws {
        let service = MotionRecipeService()
        let project = sampleProject(workspaceURL: temporaryWorkspaceURL())
        let scenes = sampleScenes(count: 16)

        for name in [
            "slow_archive_build",
            "high_energy_trailer",
            "problem_image_safe_insert",
            "vertical_social_cut"
        ] {
            let recipeText = try readExampleRecipe(named: name)
            let result = service.validate(recipeText: recipeText, currentScenes: scenes, project: project)
            XCTAssertFalse(result.hasErrors, "Expected \(name) to validate cleanly, got: \(result.issues.map(\.message))")
        }
    }

    func testMalformedRecipeFailsValidation() {
        let service = MotionRecipeService()
        let result = service.validate(recipeText: "{", currentScenes: sampleScenes(), project: sampleProject(workspaceURL: temporaryWorkspaceURL()))
        XCTAssertTrue(result.hasErrors)
        XCTAssertEqual(result.issues.first?.code, "malformed_json")
    }

    func testUnsupportedSchemaVersionFailsValidation() {
        let service = MotionRecipeService()
        let recipe = exampleRecipe()
        let text = jsonString(recipe: recipe, schemaVersion: 2)
        let result = service.validate(recipeText: text, currentScenes: sampleScenes(count: 4), project: sampleProject(workspaceURL: temporaryWorkspaceURL()))
        XCTAssertTrue(result.issues.contains { $0.code == "unsupported_schema_version" })
        XCTAssertTrue(result.hasErrors)
    }

    func testInvalidTargetRangeFailsValidation() {
        let service = MotionRecipeService()
        var recipe = exampleRecipe()
        recipe.target.sceneRange = MotionRecipeSceneRange(start: 4, end: 2)
        let result = service.validate(recipeText: encode(recipe), currentScenes: sampleScenes(count: 4), project: sampleProject(workspaceURL: temporaryWorkspaceURL()))
        XCTAssertTrue(result.issues.contains { $0.code == "target_range_order" })
        XCTAssertTrue(result.hasErrors)
    }

    func testOverlappingSectionsProduceWarning() {
        let service = MotionRecipeService()
        var recipe = exampleRecipe()
        recipe.sections = [
            MotionRecipeSection(
                name: "A",
                sceneRange: MotionRecipeSceneRange(start: 1, end: 3),
                durationSeconds: 3,
                motionPreset: .slowPushIn,
                transitionIn: "cut",
                transitionOut: "cut",
                notes: ""
            ),
            MotionRecipeSection(
                name: "B",
                sceneRange: MotionRecipeSceneRange(start: 3, end: 4),
                durationSeconds: 4,
                motionPreset: .panLeft,
                transitionIn: "cut",
                transitionOut: "fade",
                notes: ""
            )
        ]
        let result = service.validate(recipeText: encode(recipe), currentScenes: sampleScenes(count: 4), project: sampleProject(workspaceURL: temporaryWorkspaceURL()))
        XCTAssertTrue(result.issues.contains { $0.code == "overlapping_sections" })
        XCTAssertTrue(result.hasWarnings)
    }

    func testPreviewAndApplyUseSectionAndOverrideOrdering() throws {
        let service = MotionRecipeService()
        let scenes = sampleScenes(count: 4)
        let workspaceURL = temporaryWorkspaceURL()
        let project = sampleProject(workspaceURL: workspaceURL)
        let workspaceService = WorkspaceService()

        try workspaceService.save(project: project, scenes: scenes, importReport: nil, to: workspaceURL)

        let recipe = recipeForApplyTest()
        let preview = service.preview(recipe: recipe, currentScenes: scenes, project: project)
        XCTAssertEqual(preview.affectedSceneCount, 3)
        XCTAssertEqual(preview.durationChangesCount, 3)
        XCTAssertEqual(preview.motionPresetChangesCount, 2)
        XCTAssertEqual(preview.transitionChangesCount, 3)
        XCTAssertEqual(preview.affectedScenes.first?.sequenceIndex, 2)

        let result = try service.apply(
            recipe: recipe,
            project: project,
            currentScenes: scenes,
            importReport: nil,
            workspaceURL: workspaceURL
        )

        XCTAssertEqual(result.recipeName, "Apply Test")
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.backupPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.appliedRecipePath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.reportPath))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.outputScenePlanPath))

        let scenePlan = try JSONFileStore().read(ScenePlan.self, from: workspaceURL.appendingPathComponent("scene_plan.json"))
        XCTAssertEqual(scenePlan.scenes.map(\.sequenceIndex), [1, 2, 3, 4])
        XCTAssertEqual(scenePlan.scenes.map(\.sourcePath), scenes.map(\.sourcePath))
        XCTAssertEqual(scenePlan.scenes[0].durationSeconds, 3)
        XCTAssertEqual(scenePlan.scenes[1].motionPreset, .panLeft)
        XCTAssertEqual(scenePlan.scenes[2].durationSeconds, 4)
        XCTAssertEqual(scenePlan.scenes[2].motionPreset, .lockedOff)
    }

    func testInvalidDurationAndFpsAreRejected() {
        let service = MotionRecipeService()
        var recipe = exampleRecipe()
        recipe.globalDefaults.durationSeconds = 0
        recipe.globalRenderSettings.fps = 0
        let result = service.validate(recipeText: encode(recipe), currentScenes: sampleScenes(count: 4), project: sampleProject(workspaceURL: temporaryWorkspaceURL()))
        XCTAssertTrue(result.issues.contains { $0.code == "invalid_default_duration" })
        XCTAssertTrue(result.issues.contains { $0.code == "invalid_fps" })
        XCTAssertTrue(result.hasErrors)
    }

    private func readExampleRecipe(named name: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = root.appendingPathComponent("examples/recipes/\(name).json")
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func sampleProject(workspaceURL: URL) -> AnimateProject {
        AnimateProject(
            projectName: "Test Project",
            createdAt: .now,
            updatedAt: .now,
            sourceKind: .folder,
            sourcePath: "/tmp/source",
            workspacePath: workspaceURL.path,
            scenePlanPath: "scene_plan.json",
            renderSettings: .default
        )
    }

    private func sampleScenes(count: Int = 4) -> [SceneItem] {
        (1...count).map { index in
            SceneItem(
                id: "scene-\(index)",
                sequenceIndex: index,
                filename: "image\(index).png",
                sourcePath: "/tmp/image\(index).png",
                workingPath: "/tmp/working/image\(index).png",
                width: 1920,
                height: 1080,
                fileSizeBytes: 1000,
                durationSeconds: 3,
                motionPreset: .lockedOff,
                transitionIn: "cut",
                transitionOut: "cut",
                caption: "",
                notes: "",
                validationStatus: "ok",
                validationIssues: [],
                fileExtension: "png",
                orientation: .up,
                dominantProjectSize: "1920x1080",
                differsFromDominantSize: false,
                readable: true,
                explicitSequenceNumber: index,
                importOrder: index
            )
        }
    }

    private func exampleRecipe() -> MotionRecipe {
        MotionRecipe(
            schemaVersion: 1,
            recipeName: "Apply Test",
            description: "Base recipe used by tests.",
            target: MotionRecipeTarget(
                matchMode: "sequenceIndex",
                sceneRange: MotionRecipeSceneRange(start: 1, end: 4)
            ),
            globalRenderSettings: MotionRecipeGlobalRenderSettings(
                outputWidth: 1920,
                outputHeight: 1080,
                fps: 30,
                defaultSceneDuration: 3
            ),
            globalDefaults: MotionRecipeGlobalDefaults(
                durationSeconds: 3,
                motionPreset: .lockedOff,
                transitionIn: "cut",
                transitionOut: "cut"
            ),
            sections: [
                MotionRecipeSection(
                    name: "Middle",
                    sceneRange: MotionRecipeSceneRange(start: 2, end: 4),
                    durationSeconds: 4,
                    motionPreset: .panLeft,
                    transitionIn: "fade",
                    transitionOut: "cut",
                    notes: ""
                )
            ],
            sceneOverrides: [
                MotionRecipeSceneOverride(
                    sequenceIndex: 3,
                    durationSeconds: 4,
                    motionPreset: .lockedOff,
                    transitionIn: "fade",
                    transitionOut: "fade",
                    notes: "override",
                    sceneId: nil,
                    filenameContains: nil
                )
            ]
        )
    }

    private func recipeForApplyTest() -> MotionRecipe {
        exampleRecipe()
    }

    private func encode(_ recipe: MotionRecipe, schemaVersion: Int? = nil) -> String {
        var mutable = recipe
        if let schemaVersion {
            mutable.schemaVersion = schemaVersion
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(mutable) else {
            return ""
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func jsonString(recipe: MotionRecipe, schemaVersion: Int) -> String {
        encode(recipe, schemaVersion: schemaVersion)
    }

    private func temporaryWorkspaceURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("animdex-motion-recipe-\(UUID().uuidString)", isDirectory: true)
    }
}

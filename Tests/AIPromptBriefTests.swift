import XCTest
@testable import AnimateDex

final class AIPromptBriefTests: XCTestCase {
    func testPromptBriefIncludesProjectContextAndPresetList() {
        let service = AIPromptBriefService()
        let project = AnimateProject(
            projectName: "Brief Project",
            createdAt: .now,
            updatedAt: .now,
            sourceKind: .folder,
            sourcePath: "/tmp/source",
            workspacePath: "/tmp/workspace",
            scenePlanPath: "scene_plan.json",
            renderSettings: RenderSettings(
                outputWidth: 1080,
                outputHeight: 1920,
                fps: 30,
                defaultSceneDuration: 2.5,
                transitionDuration: 0.5,
                outputFilename: "proof.mp4",
                outputFormat: "mp4",
                videoCodec: "libx264",
                pixelFormat: "yuv420p"
            )
        )
        let scenes = [
            sampleScene(sequenceIndex: 1, filename: "alpha.png", width: 1080, height: 1920),
            sampleScene(sequenceIndex: 2, filename: "beta.png", width: 1080, height: 1920, validationStatus: "warning", differsFromDominantSize: true)
        ]

        let brief = service.makePromptBrief(project: project, scenes: scenes, renderSettings: project.renderSettings)

        XCTAssertTrue(brief.contains("Scene count: 2"))
        XCTAssertTrue(brief.contains("Sequence range: 1-2"))
        XCTAssertTrue(brief.contains("1080x1920"))
        XCTAssertTrue(brief.contains("Irregular scenes"))
        XCTAssertTrue(brief.contains("beta.png"))
        XCTAssertTrue(brief.contains("locked_off"))
        XCTAssertTrue(brief.contains("problem_insert"))
    }

    private func sampleScene(
        sequenceIndex: Int,
        filename: String,
        width: Int,
        height: Int,
        validationStatus: String = "ok",
        differsFromDominantSize: Bool = false
    ) -> SceneItem {
        SceneItem(
            id: "scene-\(sequenceIndex)",
            sequenceIndex: sequenceIndex,
            filename: filename,
            sourcePath: "/tmp/\(filename)",
            workingPath: "/tmp/working/\(filename)",
            width: width,
            height: height,
            fileSizeBytes: 1234,
            durationSeconds: 2,
            motionPreset: .lockedOff,
            transitionIn: "cut",
            transitionOut: "cut",
            caption: "",
            notes: "",
            validationStatus: validationStatus,
            validationIssues: differsFromDominantSize ? [ValidationIssue(severity: .warning, code: "size", message: "size differs")] : [],
            fileExtension: "png",
            orientation: .up,
            dominantProjectSize: "1080x1920",
            differsFromDominantSize: differsFromDominantSize,
            readable: true,
            explicitSequenceNumber: sequenceIndex,
            importOrder: sequenceIndex
        )
    }
}

import XCTest
@testable import AnimateDex

final class AppViewModelDiagnosticsTests: XCTestCase {
    @MainActor
    func testDiagnosticsTextIncludesKeyFields() {
        let viewModel = AppViewModel()
        viewModel.activeProject = AnimateProject(
            projectName: "Diagnostics Project",
            createdAt: .now,
            updatedAt: .now,
            sourceKind: .folder,
            sourcePath: "/tmp/source",
            workspacePath: "/tmp/workspace.animdex",
            scenePlanPath: "scene_plan.json",
            renderSettings: .default,
            lastMotionRecipeName: "Recipe"
        )
        viewModel.scenes = [
            sampleScene(sequenceIndex: 1),
            sampleScene(sequenceIndex: 2)
        ]
        viewModel.validationIssues = [
            ValidationIssue(severity: .warning, code: "sample", message: "Example warning")
        ]
        viewModel.statusMessage = "Import complete"
        viewModel.statusDetails = "Imported 2 scenes."
        viewModel.statusPath = "/tmp/workspace.animdex"
        viewModel.statusSuggestion = "Review the sequence."
        viewModel.renderLogPath = "/tmp/workspace.animdex/logs/render_log.txt"
        viewModel.lastErrorNotice = AppNotice(
            kind: .error,
            title: "Render failed",
            summary: "ffmpeg missing",
            details: "ffmpeg not found on PATH",
            path: "/tmp/workspace.animdex/logs/render_log.txt",
            suggestion: "Install ffmpeg with Homebrew."
        )

        let diagnostics = viewModel.diagnosticsText
        XCTAssertTrue(diagnostics.contains("Project path: /tmp/workspace.animdex"))
        XCTAssertTrue(diagnostics.contains("Source path: /tmp/source"))
        XCTAssertTrue(diagnostics.contains("Scene count: 2"))
        XCTAssertTrue(diagnostics.contains("Validation issues: 1"))
        XCTAssertTrue(diagnostics.contains("Render log path: /tmp/workspace.animdex/logs/render_log.txt"))
        XCTAssertTrue(diagnostics.contains("Last error:"))
        XCTAssertTrue(diagnostics.contains("ffmpeg not found on PATH"))
    }

    @MainActor
    func testRenderOutputPathUsesCurrentFilename() {
        let viewModel = AppViewModel()
        viewModel.activeProject = AnimateProject(
            projectName: "Render Project",
            createdAt: .now,
            updatedAt: .now,
            sourceKind: .folder,
            sourcePath: "/tmp/source",
            workspacePath: "/tmp/render.animdex",
            scenePlanPath: "scene_plan.json",
            renderSettings: RenderSettings(
                outputWidth: 1920,
                outputHeight: 1080,
                fps: 30,
                defaultSceneDuration: 3,
                transitionDuration: 0.5,
                outputFilename: "proof_render.mp4",
                outputFormat: "mp4",
                videoCodec: "libx264",
                pixelFormat: "yuv420p"
            )
        )

        XCTAssertEqual(viewModel.renderOutputPath, "/tmp/render.animdex/exports/proof_render.mp4")
    }

    @MainActor
    private func sampleScene(sequenceIndex: Int) -> SceneItem {
        SceneItem(
            id: "scene-\(sequenceIndex)",
            sequenceIndex: sequenceIndex,
            filename: "image\(sequenceIndex).png",
            sourcePath: "/tmp/image\(sequenceIndex).png",
            workingPath: "/tmp/working/image\(sequenceIndex).png",
            width: 100,
            height: 100,
            fileSizeBytes: 1,
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
            dominantProjectSize: "100x100",
            differsFromDominantSize: false,
            readable: true,
            explicitSequenceNumber: sequenceIndex,
            importOrder: sequenceIndex
        )
    }
}

import AppKit
import Observation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class AppViewModel {
    private let workspaceService = WorkspaceService()
    private let importService = ImportService()
    private let renderService = RenderService()
    private let motionRecipeService = MotionRecipeService()
    private let promptBriefService = AIPromptBriefService()
    private let jsonStore = JSONFileStore()

    var activeProject: AnimateProject?
    var scenes: [SceneItem] = []
    var importReport: ImportReport?
    var validationIssues: [ValidationIssue] = []
    var renderSettings = RenderSettings.default
    var selectedSceneID: String?
    var statusMessage: String = "Ready"
    var renderLog: String = ""
    var renderProgress: Double = 0
    var isBusy: Bool = false
    var automationDidRun = false
    var motionRecipeText: String = ""
    var motionRecipeValidationResult: MotionRecipeValidationResult?
    var motionRecipePreview: MotionRecipePreview?
    var motionRecipeApplicationResult: MotionRecipeApplicationResult?
    var motionRecipeStatusMessage: String = "Paste a Motion Recipe JSON object."

    var hasActiveProject: Bool {
        activeProject != nil
    }

    var selectedScene: SceneItem? {
        guard let selectedSceneID else { return scenes.first }
        return scenes.first { $0.id == selectedSceneID }
    }

    var workspaceSummary: String {
        guard let activeProject else { return "No workspace open" }
        return activeProject.workspacePath
    }

    func createNewProject() {
        Task { @MainActor in
            do {
                guard let workspaceURL = try workspaceService.chooseWorkspaceForNewProject() else {
                    statusMessage = "New project cancelled"
                    return
                }
                try await openWorkspace(at: workspaceURL)
            } catch {
                statusMessage = "Failed to create workspace: \(error.localizedDescription)"
            }
        }
    }

    func openExistingProject() {
        Task { @MainActor in
            do {
                guard let workspaceURL = try workspaceService.chooseExistingWorkspace() else {
                    statusMessage = "Open project cancelled"
                    return
                }
                try await openWorkspace(at: workspaceURL)
            } catch {
                statusMessage = "Failed to open workspace: \(error.localizedDescription)"
            }
        }
    }

    func importFolderOrZip() {
        guard let activeProject else {
            statusMessage = "Open a project first"
            return
        }

        Task {
            await performImport(into: activeProject)
        }
    }

    func renderProject() {
        guard let activeProject else {
            statusMessage = "Open a project first"
            return
        }

        Task {
            await performRender(project: activeProject)
        }
    }

    func openExportsFolder() {
        guard let activeProject else { return }
        let exportsURL = URL(fileURLWithPath: activeProject.workspacePath).appendingPathComponent("exports")
        NSWorkspace.shared.open(exportsURL)
    }

    func loadMotionRecipeExample(_ example: MotionRecipeExample) {
        motionRecipeText = example.json
        motionRecipeApplicationResult = nil
        validateMotionRecipe()
        motionRecipeStatusMessage = "Loaded example: \(example.title)"
    }

    func copyAIPromptBrief() {
        guard let activeProject else {
            motionRecipeStatusMessage = "Open a project before copying a prompt brief."
            return
        }

        let brief = promptBriefService.makePromptBrief(
            project: activeProject,
            scenes: scenes,
            renderSettings: renderSettings
        )
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(brief, forType: .string)
        motionRecipeStatusMessage = "Copied AI prompt brief to the clipboard."
    }

    func clearMotionRecipe() {
        motionRecipeText = ""
        motionRecipeValidationResult = nil
        motionRecipePreview = nil
        motionRecipeApplicationResult = nil
        motionRecipeStatusMessage = "Motion Recipe cleared."
    }

    func validateMotionRecipe() {
        let result = motionRecipeService.validate(
            recipeText: motionRecipeText,
            currentScenes: scenes,
            project: activeProject
        )
        motionRecipeValidationResult = result
        motionRecipeApplicationResult = nil
        motionRecipePreview = nil

        if result.issues.isEmpty {
            motionRecipeStatusMessage = "Motion Recipe is valid."
        } else {
            let errorCount = result.issues.filter { $0.severity == .error }.count
            let warningCount = result.issues.filter { $0.severity == .warning }.count
            motionRecipeStatusMessage = "Validation finished: \(errorCount) error(s), \(warningCount) warning(s)."
        }
    }

    func previewMotionRecipe() {
        let result = motionRecipeService.validate(
            recipeText: motionRecipeText,
            currentScenes: scenes,
            project: activeProject
        )
        motionRecipeValidationResult = result
        motionRecipeApplicationResult = nil

        guard let recipe = result.recipe, !result.hasErrors else {
            motionRecipePreview = nil
            motionRecipeStatusMessage = "Preview unavailable until the recipe validates."
            return
        }

        motionRecipePreview = motionRecipeService.preview(
            recipe: recipe,
            currentScenes: scenes,
            project: activeProject
        )
        motionRecipeStatusMessage = "Preview updated for \(recipe.recipeName)."
    }

    func applyMotionRecipe() {
        guard let currentProject = activeProject else {
            motionRecipeStatusMessage = "Open a project before applying a Motion Recipe."
            return
        }

        let result = motionRecipeService.validate(
            recipeText: motionRecipeText,
            currentScenes: scenes,
            project: currentProject
        )
        motionRecipeValidationResult = result
        guard let recipe = result.recipe, !result.hasErrors else {
            motionRecipePreview = nil
            motionRecipeStatusMessage = result.hasErrors ? "Motion Recipe has blocking validation errors." : "Motion Recipe is not ready."
            return
        }

        do {
            guard let workspaceURL = resultWorkspaceURL else {
                motionRecipeStatusMessage = "Open a workspace before applying a Motion Recipe."
                return
            }

            let applicationResult = try motionRecipeService.apply(
                recipe: recipe,
                project: currentProject,
                currentScenes: scenes,
                importReport: importReport,
                workspaceURL: workspaceURL
            )
            motionRecipeApplicationResult = applicationResult
            motionRecipeStatusMessage = "Applied \(applicationResult.recipeName) to \(applicationResult.changedSceneCount) scene(s)."

            let reloaded = try workspaceService.loadOrCreateProject(at: workspaceURL)
            activeProject = reloaded.project
            scenes = reloaded.scenes
            importReport = reloaded.importReport
            validationIssues = reloaded.validationIssues
            renderSettings = reloaded.project.renderSettings
            selectedSceneID = scenes.first?.id
            refreshMotionRecipeState()
        } catch {
            motionRecipeStatusMessage = "Failed to apply Motion Recipe: \(error.localizedDescription)"
        }
    }

    func updateScenePreset(sceneID: String, preset: MotionPreset) {
        guard let index = scenes.firstIndex(where: { $0.id == sceneID }) else { return }
        scenes[index].motionPreset = preset
        selectedSceneID = sceneID

        guard var project = activeProject else { return }
        project.updatedAt = .now
        project.renderSettings = renderSettings
        activeProject = project

        do {
            try workspaceService.save(
                project: project,
                scenes: scenes,
                importReport: importReport,
                to: URL(fileURLWithPath: project.workspacePath)
            )
        } catch {
            statusMessage = "Failed to save preset change: \(error.localizedDescription)"
        }

        refreshMotionRecipeState()
    }

    func runAutomationIfConfigured() async {
        guard !automationDidRun else { return }
        let environment = ProcessInfo.processInfo.environment
        guard let workspacePath = environment["ANIMATEDEX_AUTOMATION_WORKSPACE"],
              let sourcePath = environment["ANIMATEDEX_AUTOMATION_SOURCE"] else {
            return
        }

        automationDidRun = true
        let workspaceURL = URL(fileURLWithPath: workspacePath)
        let sourceURL = URL(fileURLWithPath: sourcePath)

        do {
            statusMessage = "Automation: opening workspace"
            let loaded = try workspaceService.loadOrCreateProject(at: workspaceURL)
            activeProject = loaded.project
            renderSettings = loaded.project.renderSettings

            statusMessage = "Automation: importing source"
            let importResult = try await importService.importSource(
                sourceURL: sourceURL,
                into: loaded.project,
                renderSettings: renderSettings
            )

            activeProject = importResult.project
            scenes = importResult.scenes
            importReport = importResult.importReport
            validationIssues = importResult.validationIssues
            selectedSceneID = scenes.first?.id
            statusMessage = "Automation: import complete"
            refreshMotionRecipeState()

            if environment["ANIMATEDEX_AUTOMATION_RENDER"] == "1" {
                statusMessage = "Automation: rendering"
                let renderResult = try await renderService.render(project: importResult.project, scenes: importResult.scenes, renderSettings: renderSettings) { progress, message in
                    Task { @MainActor in
                        self.renderProgress = progress
                        self.statusMessage = message
                    }
                }
                renderLog = renderResult.renderLog
                renderProgress = 1
                statusMessage = "Automation: render complete"
            }
        } catch {
            statusMessage = "Automation failed: \(error.localizedDescription)"
            renderLog = error.localizedDescription
        }
    }

    private func openWorkspace(at workspaceURL: URL) async throws {
        let project = try workspaceService.loadOrCreateProject(at: workspaceURL)
        activeProject = project.project
        scenes = project.scenes
        renderSettings = project.project.renderSettings
        importReport = project.importReport
        validationIssues = project.validationIssues
        selectedSceneID = scenes.first?.id
        statusMessage = "Workspace open: \(workspaceURL.lastPathComponent)"
        refreshMotionRecipeState()
    }

    private func performImport(into project: AnimateProject) async {
        do {
            isBusy = true
            defer { isBusy = false }
            statusMessage = "Importing media..."

            guard let sourceURL = try workspaceService.chooseImportSource() else {
                statusMessage = "Import cancelled"
                return
            }

            let result = try await importService.importSource(
                sourceURL: sourceURL,
                into: project,
                renderSettings: renderSettings
            )

            activeProject = result.project
            scenes = result.scenes
            importReport = result.importReport
            validationIssues = result.validationIssues
            selectedSceneID = scenes.first?.id
            statusMessage = "Imported \(scenes.count) scenes"
            refreshMotionRecipeState()
        } catch {
            statusMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private func performRender(project: AnimateProject) async {
        do {
            isBusy = true
            defer { isBusy = false }
            statusMessage = "Rendering..."
            renderProgress = 0

            let result = try await renderService.render(
                project: project,
                scenes: scenes,
                renderSettings: renderSettings
            ) { progress, message in
                Task { @MainActor in
                    self.renderProgress = progress
                    self.statusMessage = message
                }
            }

            renderLog = result.renderLog
            renderProgress = 1
            statusMessage = result.success ? "Render complete" : "Render finished with issues"
        } catch {
            renderLog = error.localizedDescription
            statusMessage = "Render failed: \(error.localizedDescription)"
        }
    }

    private var resultWorkspaceURL: URL? {
        activeProject.map { URL(fileURLWithPath: $0.workspacePath) }
    }

    private func refreshMotionRecipeState() {
        guard !motionRecipeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            motionRecipeValidationResult = nil
            motionRecipePreview = nil
            return
        }

        let result = motionRecipeService.validate(
            recipeText: motionRecipeText,
            currentScenes: scenes,
            project: activeProject
        )
        motionRecipeValidationResult = result

        guard let recipe = result.recipe, !result.hasErrors else {
            motionRecipePreview = nil
            return
        }

        motionRecipePreview = motionRecipeService.preview(
            recipe: recipe,
            currentScenes: scenes,
            project: activeProject
        )
    }
}

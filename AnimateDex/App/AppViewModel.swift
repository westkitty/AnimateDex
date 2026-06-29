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

    var activeProject: AnimateProject?
    var scenes: [SceneItem] = []
    var importReport: ImportReport?
    var validationIssues: [ValidationIssue] = []
    var renderSettings = RenderSettings.default
    var selectedSceneID: String?
    var selectedSection: AppWorkflowSection = .overview

    var statusMessage: String = "Ready"
    var statusDetails: String = "Open a project or import media to continue."
    var statusPath: String?
    var statusSuggestion: String?
    var statusKind: AppNotice.Kind = .info

    var renderLog: String = ""
    var renderLogPath: String = ""
    var renderProgress: Double = 0
    var isBusy: Bool = false
    var automationDidRun = false

    var motionRecipeText: String = ""
    var motionRecipeValidationResult: MotionRecipeValidationResult?
    var motionRecipePreview: MotionRecipePreview?
    var motionRecipeApplicationResult: MotionRecipeApplicationResult?
    var motionRecipeStatusMessage: String = "Paste a Motion Recipe JSON object."

    var lastImportNotice: AppNotice?
    var lastRenderNotice: AppNotice?
    var lastRecipeNotice: AppNotice?
    var lastErrorNotice: AppNotice?

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

    var workspaceShortSummary: String {
        guard let activeProject else { return "No workspace open" }
        return URL(fileURLWithPath: activeProject.workspacePath).lastPathComponent
    }

    var diagnosticsText: String {
        var lines: [String] = []
        lines.append("Status: \(statusMessage)")
        lines.append("Status details: \(statusDetails)")
        if let statusPath {
            lines.append("Status path: \(statusPath)")
        }
        if let statusSuggestion {
            lines.append("Status suggestion: \(statusSuggestion)")
        }
        lines.append("Project path: \(activeProject?.workspacePath ?? "none")")
        lines.append("Source path: \(activeProject?.sourcePath ?? "none")")
        lines.append("Scene count: \(scenes.count)")
        lines.append("Validation issues: \(validationIssues.count)")
        lines.append("Import report path: \(importReportPath ?? "none")")
        lines.append("Render log path: \(renderLogPath.isEmpty ? "none" : renderLogPath)")
        lines.append("Output path: \(renderOutputPath ?? "none")")
        lines.append("Recipe report path: \(lastRecipeNotice?.path ?? "none")")
        if let lastErrorNotice {
            lines.append("")
            lines.append("Last error:")
            lines.append(lastErrorNotice.copyText)
        }
        return lines.joined(separator: "\n")
    }

    var statusCopyText: String {
        var lines: [String] = []
        lines.append("Status: \(statusMessage)")
        lines.append(statusDetails)
        if let statusPath {
            lines.append("Path: \(statusPath)")
        }
        if let statusSuggestion {
            lines.append("Suggestion: \(statusSuggestion)")
        }
        return lines.joined(separator: "\n")
    }

    var renderOutputPath: String? {
        activeProject.map { URL(fileURLWithPath: $0.workspacePath).appendingPathComponent("exports").appendingPathComponent(renderSettings.outputFilename).path }
    }

    private var importReportPath: String? {
        activeProject.map { URL(fileURLWithPath: $0.workspacePath).appendingPathComponent("import_report.json").path }
    }

    func createNewProject() {
        Task { @MainActor in
            do {
                guard let workspaceURL = try workspaceService.chooseWorkspaceForNewProject() else {
                    resetToIdleState()
                    return
                }
                try await openWorkspace(at: workspaceURL)
            } catch {
                recordError(
                    title: "Create workspace failed",
                    details: error.localizedDescription,
                    path: nil,
                    suggestion: "Choose a different destination folder."
                )
            }
        }
    }

    func openExistingProject() {
        Task { @MainActor in
            do {
                guard let workspaceURL = try workspaceService.chooseExistingWorkspace() else {
                    resetToIdleState()
                    return
                }
                try await openWorkspace(at: workspaceURL)
            } catch {
                recordError(
                    title: "Open workspace failed",
                    details: error.localizedDescription,
                    path: nil,
                    suggestion: "Choose a valid .animdex workspace."
                )
            }
        }
    }

    func importFolderOrZip() {
        Task {
            await performImportFlow()
        }
    }

    func renderProject() {
        guard let activeProject else {
            recordError(
                title: "Render blocked",
                details: "Open a project with scenes before rendering a proof MP4.",
                path: nil,
                suggestion: "Import an image folder or ZIP first."
            )
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

    func openWorkspaceFolder() {
        guard let activeProject else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: activeProject.workspacePath))
    }

    func revealWorkspaceInFinder() {
        guard let activeProject else { return }
        let workspaceURL = URL(fileURLWithPath: activeProject.workspacePath)
        NSWorkspace.shared.activateFileViewerSelecting([workspaceURL])
    }

    func revealExportsInFinder() {
        guard let activeProject else { return }
        let exportsURL = URL(fileURLWithPath: activeProject.workspacePath).appendingPathComponent("exports")
        NSWorkspace.shared.activateFileViewerSelecting([exportsURL])
    }

    func revealLastRender() {
        guard let outputPath = renderOutputPath else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: outputPath)])
    }

    func copyDiagnostics() {
        copyToPasteboard(diagnosticsText)
        statusMessage = "Diagnostics copied"
        statusDetails = "Copied workspace, status, and output paths to the clipboard."
        statusKind = .info
    }

    func copyStatusDetails() {
        copyToPasteboard(statusCopyText)
        statusMessage = "Status copied"
        statusDetails = "Copied the current status and next-step text to the clipboard."
        statusKind = .info
    }

    func copyLastError() {
        guard let lastErrorNotice else { return }
        copyToPasteboard(lastErrorNotice.copyText)
        statusMessage = "Last error copied"
        statusDetails = "Copied the most recent error to the clipboard."
        statusKind = .info
    }

    func copyWorkspacePath() {
        guard let activeProject else { return }
        copyToPasteboard(activeProject.workspacePath)
        statusMessage = "Workspace path copied"
        statusDetails = activeProject.workspacePath
    }

    func copyRenderLog() {
        guard !renderLog.isEmpty else { return }
        copyToPasteboard(renderLog)
        statusMessage = "Render log copied"
        statusDetails = "Copied the current render log to the clipboard."
    }

    func loadMotionRecipeExample(_ example: MotionRecipeExample) {
        motionRecipeText = example.json
        motionRecipeApplicationResult = nil
        validateMotionRecipe()
        motionRecipeStatusMessage = "Loaded example: \(example.title)"
        lastRecipeNotice = AppNotice(
            kind: .info,
            title: "Motion Recipe example loaded",
            summary: example.title,
            details: "Loaded bundled example JSON into the editor.",
            path: nil,
            suggestion: "Validate the recipe before applying it."
        )
        selectedSection = .motionRecipe
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
        setStatus(
            title: "Prompt brief copied",
            details: "The Motion Recipe prompt brief is on the clipboard.",
            suggestion: "Paste it into an external AI tool and request JSON only."
        )
        lastRecipeNotice = AppNotice(
            kind: .info,
            title: "Prompt brief copied",
            summary: "Motion Recipe brief copied to clipboard.",
            details: "Copied a deterministic prompt brief for external AI use.",
            path: nil,
            suggestion: "Paste the brief into a text-only AI chat."
        )
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
        lastRecipeNotice = AppNotice(
            kind: result.hasErrors ? .error : (result.hasWarnings ? .warning : .info),
            title: "Motion Recipe validation",
            summary: result.hasErrors ? "Blocking errors found" : "Validation complete",
            details: result.issues.map(\.message).joined(separator: "\n"),
            path: nil,
            suggestion: result.hasErrors ? "Fix the blocking errors and validate again." : "Preview or apply the recipe."
        )

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
        lastRecipeNotice = AppNotice(
            kind: .info,
            title: "Motion Recipe preview",
            summary: "Preview updated for \(recipe.recipeName)",
            details: "Affected scenes: \(motionRecipePreview?.affectedSceneCount ?? 0).",
            path: nil,
            suggestion: "Apply the recipe if the preview looks correct."
        )
        selectedSection = .motionRecipe
    }

    func showSection(_ section: AppWorkflowSection) {
        selectedSection = section
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
            lastRecipeNotice = AppNotice(
                kind: .info,
                title: "Motion Recipe applied",
                summary: applicationResult.recipeName,
                details: "Changed scenes: \(applicationResult.changedSceneCount). Backup and report files were written.",
                path: applicationResult.reportPath,
                suggestion: "Open the report or render the workspace to verify the output."
            )

            let reloaded = try workspaceService.loadOrCreateProject(at: workspaceURL)
            activeProject = reloaded.project
            scenes = reloaded.scenes
            importReport = reloaded.importReport
            validationIssues = reloaded.validationIssues
            renderSettings = reloaded.project.renderSettings
            selectedSceneID = scenes.first?.id
            statusPath = reloaded.project.workspacePath
            statusSuggestion = scenes.isEmpty ? "Import an image folder or ZIP." : "Review the Sequence and Render sections."
            statusKind = .info
            selectedSection = .motionRecipe
            refreshMotionRecipeState()
        } catch {
            recordError(
                title: "Motion Recipe apply failed",
                details: error.localizedDescription,
                path: activeProject?.workspacePath,
                suggestion: "Fix the recipe errors or restore the workspace from the backup plan."
            )
            motionRecipeStatusMessage = "Failed to apply Motion Recipe."
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
            recordError(
                title: "Failed to save preset change",
                details: error.localizedDescription,
                path: project.workspacePath,
                suggestion: "Try saving again after verifying workspace permissions."
            )
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
            setStatus(
                title: "Automation",
                details: "Opening workspace."
            )
            let loaded = try workspaceService.loadOrCreateProject(at: workspaceURL)
            activeProject = loaded.project
            renderSettings = loaded.project.renderSettings

            setStatus(
                title: "Automation",
                details: "Importing source media."
            )
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
            setStatus(
                title: "Automation complete",
                details: "Imported \(scenes.count) scenes from \(sourceURL.lastPathComponent).",
                path: workspaceURL.path,
                suggestion: "Review the Sequence and Motion Recipe sections."
            )
            lastImportNotice = AppNotice(
                kind: importResult.validationIssues.contains(where: { $0.severity == .error }) ? .error : .info,
                title: "Automation import complete",
                summary: "\(scenes.count) scenes imported",
                details: "Source: \(sourceURL.path)\nWorkspace: \(importResult.project.workspacePath)\nValidation issues: \(importResult.validationIssues.count)",
                path: importResult.project.workspacePath,
                suggestion: "Review the Sequence and Diagnostics sections."
            )
            selectedSection = .sequence
            refreshMotionRecipeState()

            if environment["ANIMATEDEX_AUTOMATION_RENDER"] == "1" {
                setStatus(title: "Automation", details: "Rendering proof MP4.")
                let renderResult = try await renderService.render(
                    project: importResult.project,
                    scenes: importResult.scenes,
                    renderSettings: renderSettings,
                    motionRecipeName: importResult.project.lastMotionRecipeName
                ) { progress, message in
                    Task { @MainActor in
                        self.renderProgress = progress
                        self.statusMessage = message
                    }
                }
                renderLog = renderResult.renderLog
                renderLogPath = renderResult.renderLogURL.path
                renderProgress = 1
                setStatus(
                    title: "Automation complete",
                    details: "Render complete.",
                    path: renderResult.outputURL.path,
                    suggestion: "Open the exports folder to inspect the output."
                )
                lastRenderNotice = AppNotice(
                    kind: .info,
                    title: "Automation render complete",
                    summary: renderResult.outputURL.lastPathComponent,
                    details: "Output: \(renderResult.outputURL.path)\nManifest: \(renderResult.manifestURL.path)\nLog: \(renderResult.renderLogURL.path)",
                    path: renderResult.outputURL.path,
                    suggestion: "Open the exports folder or the MP4 file in Finder."
                )
            }
        } catch {
            recordError(
                title: "Automation failed",
                details: error.localizedDescription,
                path: workspaceURL.path,
                suggestion: "Open the app manually and try the steps interactively."
            )
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
        setStatus(
            title: "Workspace open",
            details: "Loaded \(project.project.projectName) from \(workspaceURL.path).",
            path: workspaceURL.path,
            suggestion: scenes.isEmpty ? "Import an image folder or ZIP to populate the scene plan." : "Review the Sequence and Motion Recipe sections."
        )
        selectedSection = scenes.isEmpty ? .overview : .sequence
        refreshMotionRecipeState()
    }

    private func performImportFlow() async {
        do {
            isBusy = true
            defer { isBusy = false }
            setStatus(title: "Importing media", details: "Choose a folder or ZIP, then pick a workspace destination.")

            guard let sourceURL = try workspaceService.chooseImportSource() else {
                resetToIdleState()
                return
            }

            if let project = activeProject {
                await performImport(into: project, sourceURL: sourceURL)
                return
            }

            guard let workspaceURL = try workspaceService.chooseWorkspaceForImport(
                suggestedName: sourceURL.deletingPathExtension().lastPathComponent
            ) else {
                resetToIdleState()
                return
            }

            let workspace = try workspaceService.loadOrCreateProject(at: workspaceURL)
            await performImport(into: workspace.project, sourceURL: sourceURL, workspaceURL: workspaceURL)
        } catch {
            recordError(
                title: "Import failed",
                details: error.localizedDescription,
                path: activeProject?.workspacePath,
                suggestion: "Check the source file or folder and try again."
            )
        }
    }

    private func performImport(into project: AnimateProject, sourceURL: URL, workspaceURL: URL? = nil) async {
        do {
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
            setStatus(
                title: "Import complete",
                details: "Imported \(scenes.count) scenes from \(sourceURL.lastPathComponent).",
                path: result.project.workspacePath,
                suggestion: scenes.isEmpty ? "Import a usable image set." : "Review the Sequence and Diagnostics sections."
            )
            statusKind = result.validationIssues.contains(where: { $0.severity == .error }) ? .error : .info
            lastImportNotice = AppNotice(
                kind: result.validationIssues.contains(where: { $0.severity == .error }) ? .error : .info,
                title: "Import complete",
                summary: "\(scenes.count) scenes imported",
                details: "Source: \(sourceURL.path)\nWorkspace: \(result.project.workspacePath)\nValidation issues: \(result.validationIssues.count)",
                path: result.project.workspacePath,
                suggestion: "Review the Sequence and Diagnostics sections."
            )
            selectedSection = .sequence
            refreshMotionRecipeState()
        } catch {
            recordError(
                title: "Import failed",
                details: error.localizedDescription,
                path: workspaceURL?.path ?? activeProject?.workspacePath,
                suggestion: "Check the source file or folder and try again."
            )
        }
    }

    private func performRender(project: AnimateProject) async {
        do {
            isBusy = true
            defer { isBusy = false }
            setStatus(title: "Rendering", details: "Writing MP4 and manifest files.")
            renderProgress = 0

            let result = try await renderService.render(
                project: project,
                scenes: scenes,
                renderSettings: renderSettings,
                motionRecipeName: activeProject?.lastMotionRecipeName
            ) { progress, message in
                Task { @MainActor in
                    self.renderProgress = progress
                    self.statusMessage = message
                }
            }

            renderLog = result.renderLog
            renderLogPath = result.renderLogURL.path
            renderProgress = 1
            setStatus(
                title: "Render complete",
                details: "Output written to \(result.outputURL.path)",
                path: result.outputURL.path,
                suggestion: "Open the exports folder or the MP4 file in Finder."
            )
            lastRenderNotice = AppNotice(
                kind: .info,
                title: "Render complete",
                summary: result.outputURL.lastPathComponent,
                details: "Output: \(result.outputURL.path)\nManifest: \(result.manifestURL.path)\nLog: \(result.renderLogURL.path)",
                path: result.outputURL.path,
                suggestion: "Open the exports folder or the MP4 file in Finder."
            )
            selectedSection = .render
        } catch {
            renderLog = error.localizedDescription
            setStatus(title: "Render failed", details: error.localizedDescription, path: renderLogPath.isEmpty ? renderOutputPath : renderLogPath, suggestion: "Check ffmpeg availability and the render log.", kind: .error)
            lastRenderNotice = AppNotice(
                kind: .error,
                title: "Render failed",
                summary: error.localizedDescription,
                details: error.localizedDescription,
                path: renderLogPath.isEmpty ? renderOutputPath : renderLogPath,
                suggestion: "Check ffmpeg availability and the render log."
            )
            recordError(
                title: "Render failed",
                details: error.localizedDescription,
                path: renderLogPath.isEmpty ? renderOutputPath : renderLogPath,
                suggestion: "Check ffmpeg availability and the render log."
            )
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

    private func resetToIdleState() {
        setStatus(
            title: "Ready",
            details: "No project open.",
            suggestion: "Import an image folder or ZIP, or open an existing workspace."
        )
    }

    private func setStatus(title: String, details: String, path: String? = nil, suggestion: String? = nil, kind: AppNotice.Kind = .info) {
        statusMessage = title
        statusDetails = details
        statusPath = path
        statusSuggestion = suggestion
        statusKind = kind
    }

    private func recordError(title: String, details: String, path: String?, suggestion: String?) {
        setStatus(title: title, details: details, path: path, suggestion: suggestion, kind: .error)
        lastErrorNotice = AppNotice(kind: .error, title: title, summary: title, details: details, path: path, suggestion: suggestion)
    }

    private func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

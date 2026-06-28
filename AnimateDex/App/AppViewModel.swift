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

    private func openWorkspace(at workspaceURL: URL) async throws {
        let project = try workspaceService.loadOrCreateProject(at: workspaceURL)
        activeProject = project.project
        scenes = project.scenes
        renderSettings = project.project.renderSettings
        importReport = project.importReport
        validationIssues = project.validationIssues
        selectedSceneID = scenes.first?.id
        statusMessage = "Workspace open: \(workspaceURL.lastPathComponent)"
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

            let result = try await renderService.render(project: project, scenes: scenes, renderSettings: renderSettings) { progress, message in
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
}

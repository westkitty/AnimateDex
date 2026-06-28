import AppKit
import Foundation

struct WorkspaceLoadResult: Sendable {
    let project: AnimateProject
    let scenes: [SceneItem]
    let importReport: ImportReport?
    let validationIssues: [ValidationIssue]
}

struct WorkspaceService {
    private let fileStore = JSONFileStore()

    @MainActor
    func chooseWorkspaceForNewProject() throws -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose a folder for the new AnimateDex workspace"
        panel.prompt = "Choose"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        let workspaceURL = url.pathExtension == "animdex" ? url : url.appendingPathComponent("Untitled.animdex")
        try FileManager.default.createDirectory(at: workspaceURL, withIntermediateDirectories: true)
        return workspaceURL
    }

    @MainActor
    func chooseExistingWorkspace() throws -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Open an existing AnimateDex workspace"
        panel.prompt = "Open"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        return url
    }

    @MainActor
    func chooseImportSource() throws -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Import a folder or ZIP archive"
        panel.prompt = "Import"
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.zip, .folder]

        guard panel.runModal() == .OK, let url = panel.url else {
            return nil
        }

        return url
    }

    func loadOrCreateProject(at workspaceURL: URL) throws -> WorkspaceLoadResult {
        try ensureWorkspaceLayout(at: workspaceURL)

        let projectURL = workspaceURL.appendingPathComponent("animate_project.json")
        let sceneURL = workspaceURL.appendingPathComponent("scene_plan.json")
        let importReportURL = workspaceURL.appendingPathComponent("import_report.json")

        if FileManager.default.fileExists(atPath: projectURL.path),
           FileManager.default.fileExists(atPath: sceneURL.path) {
            let project = try fileStore.read(AnimateProject.self, from: projectURL)
            let scenePlan = try fileStore.read(ScenePlan.self, from: sceneURL)
            let importReport = FileManager.default.fileExists(atPath: importReportURL.path) ? try fileStore.read(ImportReport.self, from: importReportURL) : nil
            return WorkspaceLoadResult(
                project: project,
                scenes: scenePlan.scenes,
                importReport: importReport,
                validationIssues: scenePlan.scenes.flatMap { $0.validationIssues }
            )
        }

        let projectName = workspaceURL.deletingPathExtension().lastPathComponent
        let project = AnimateProject(
            projectName: projectName,
            createdAt: .now,
            updatedAt: .now,
            sourceKind: .unknown,
            sourcePath: "",
            workspacePath: workspaceURL.path,
            scenePlanPath: "scene_plan.json",
            renderSettings: .default
        )
        try save(project: project, scenes: [], importReport: nil, to: workspaceURL)
        return WorkspaceLoadResult(project: project, scenes: [], importReport: nil, validationIssues: [])
    }

    func save(project: AnimateProject, scenes: [SceneItem], importReport: ImportReport?, to workspaceURL: URL) throws {
        try ensureWorkspaceLayout(at: workspaceURL)

        let projectURL = workspaceURL.appendingPathComponent("animate_project.json")
        let sceneURL = workspaceURL.appendingPathComponent("scene_plan.json")
        let importReportURL = workspaceURL.appendingPathComponent("import_report.json")

        try fileStore.write(project, to: projectURL)
        try fileStore.write(ScenePlan(scenes: scenes), to: sceneURL)
        if let importReport {
            try fileStore.write(importReport, to: importReportURL)
        }
    }

    private func ensureWorkspaceLayout(at workspaceURL: URL) throws {
        let fm = FileManager.default
        let directories = [
            workspaceURL,
            workspaceURL.appendingPathComponent("assets/originals"),
            workspaceURL.appendingPathComponent("assets/working"),
            workspaceURL.appendingPathComponent("exports"),
            workspaceURL.appendingPathComponent("logs"),
            workspaceURL.appendingPathComponent("temp")
        ]
        for directory in directories {
            try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }
}

struct ScenePlan: Codable, Sendable {
    var schemaVersion: Int = 1
    var scenes: [SceneItem]
}

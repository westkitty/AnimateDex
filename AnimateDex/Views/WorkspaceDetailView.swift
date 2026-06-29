import SwiftUI

struct WorkspaceDetailView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if appModel.activeProject != nil {
                    sectionHeader
                    sectionContent
                } else {
                    WorkspaceEmptyStateView(appModel: appModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var sectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(appModel.selectedSection.title)
                    .font(.title2.bold())
                Text(appModel.statusMessage)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let path = appModel.statusPath {
                Text(path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
            }
        }
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch appModel.selectedSection {
        case .overview:
            OverviewSectionView(appModel: appModel)
        case .sequence:
            SequenceSectionView(appModel: appModel)
        case .motionRecipe:
            MotionRecipeSectionView(appModel: appModel)
        case .render:
            RenderSectionView(appModel: appModel)
        case .diagnostics:
            DiagnosticsSectionView(appModel: appModel)
        }
    }
}

struct WorkspaceEmptyStateView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("No Project Open")
                    .font(.largeTitle.bold())
                Text("Import an image folder or ZIP to create an AnimateDex project, or open an existing .animdex workspace.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 12) {
                Button("Import Folder or ZIP") {
                    appModel.importFolderOrZip()
                }
                .buttonStyle(.borderedProminent)

                Button("Open Existing Project") {
                    appModel.openExistingProject()
                }

                Button("New Empty Project") {
                    appModel.createNewProject()
                }
            }

            GroupBox("What happens next") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Choose a source folder or ZIP.")
                    Text("2. Pick a workspace destination.")
                    Text("3. Review scenes, Motion Recipes, and render output.")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: 760, alignment: .leading)
        .padding(24)
    }
}

private struct OverviewSectionView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Project Overview") {
                VStack(alignment: .leading, spacing: 8) {
                    summaryRow("Project", appModel.activeProject?.projectName ?? "Unknown")
                    summaryRow("Workspace", appModel.workspaceSummary)
                    summaryRow("Source", appModel.activeProject?.sourcePath ?? "none")
                    summaryRow("Scenes", "\(appModel.scenes.count)")
                    summaryRow("Validation issues", "\(appModel.validationIssues.count)")
                    if let dominant = appModel.importReport?.dominantSize {
                        summaryRow("Dominant size", dominant)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            NoticeCard(
                title: "Current Status",
                notice: AppNotice(
                    kind: appModel.statusKind,
                    title: appModel.statusMessage,
                    summary: appModel.statusDetails,
                    details: appModel.statusDetails,
                    path: appModel.statusPath,
                    suggestion: appModel.statusSuggestion
                ),
                actionTitle: "Copy Status",
                action: appModel.copyStatusDetails
            )

            if let importNotice = appModel.lastImportNotice {
                NoticeCard(title: "Last Import", notice: importNotice, actionTitle: "Copy Diagnostics", action: appModel.copyDiagnostics)
            }
            if let renderNotice = appModel.lastRenderNotice {
                NoticeCard(title: "Last Render", notice: renderNotice, actionTitle: "Copy Diagnostics", action: appModel.copyDiagnostics)
            }
            if let recipeNotice = appModel.lastRecipeNotice {
                NoticeCard(title: "Motion Recipe", notice: recipeNotice, actionTitle: "Copy Diagnostics", action: appModel.copyDiagnostics)
            }
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
        }
    }
}

private struct SequenceSectionView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ValidationIssuesView(issues: appModel.validationIssues)
            SequenceBrowserView(scenes: appModel.scenes, selectedSceneID: $appModel.selectedSceneID)
            SceneInspectorView(appModel: appModel)
        }
    }
}

private struct MotionRecipeSectionView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NoticeCard(
                title: "Motion Recipe Brief",
                notice: AppNotice(
                    kind: .info,
                    title: "Motion Recipe",
                    summary: "Paste externally generated JSON here.",
                    details: "Copy the prompt brief, paste it into an external AI if needed, then validate the returned JSON before applying it.",
                    path: nil,
                    suggestion: "Use a bundled example or copy the AI prompt brief."
                ),
                actionTitle: "Copy Prompt Brief",
                action: appModel.copyAIPromptBrief
            )
            MotionRecipeView(appModel: appModel)
        }
    }
}

private struct RenderSectionView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Render Settings") {
                RenderSettingsView(renderSettings: $appModel.renderSettings)
            }

            GroupBox("Render Actions") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Button("Render Proof MP4") {
                            appModel.renderProject()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appModel.scenes.isEmpty)

                        Button("Open Workspace") {
                            appModel.openWorkspaceFolder()
                        }
                        .disabled(!appModel.hasActiveProject)

                        Button("Open Exports Folder") {
                            appModel.openExportsFolder()
                        }
                        .disabled(!appModel.hasActiveProject)
                    }

                    summaryRow("Output MP4", appModel.renderOutputPath ?? "none")
                    summaryRow("Render log", appModel.renderLogPath.isEmpty ? "none" : appModel.renderLogPath)

                    if let renderNotice = appModel.lastRenderNotice {
                        NoticeCard(title: "Last Render", notice: renderNotice, actionTitle: "Copy Diagnostics", action: appModel.copyDiagnostics)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            RenderProgressView(
                statusMessage: appModel.statusMessage,
                statusDetails: appModel.statusDetails,
                progressValue: appModel.renderProgress,
                renderLog: appModel.renderLog,
                outputPath: appModel.renderOutputPath,
                renderLogPath: appModel.renderLogPath,
                copyLogAction: appModel.copyRenderLog,
                openExportsAction: appModel.openExportsFolder
            )
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .textSelection(.enabled)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(2)
        }
    }
}

private struct DiagnosticsSectionView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NoticeCard(
                title: "Last Error",
                notice: appModel.lastErrorNotice ?? AppNotice(
                    kind: .info,
                    title: "No error",
                    summary: "Nothing has failed yet.",
                    details: "The app has not captured a user-facing error in this session.",
                    path: nil,
                    suggestion: "If something looks wrong, copy diagnostics and try the action again."
                ),
                actionTitle: "Copy Diagnostics",
                action: appModel.copyDiagnostics
            )

            CopyableTextCard(
                title: "Diagnostics",
                subtitle: "Copy this into ChatGPT or Codex when asking for help.",
                content: appModel.diagnosticsText,
                copyTitle: "Copy Diagnostics",
                onCopy: appModel.copyDiagnostics
            )
        }
    }
}

struct CopyableTextCard: View {
    let title: String
    let subtitle: String
    let content: String
    let copyTitle: String
    let onCopy: () -> Void

    var body: some View {
        GroupBox(title) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(copyTitle, action: onCopy)
                        .buttonStyle(.bordered)
                }

                ScrollView {
                    Text(content.isEmpty ? "No data yet." : content)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 180, maxHeight: 280)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

import SwiftUI

struct AppSidebarView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                projectActions
                projectSummary
                workflowNavigation
                statusCard
            }
            .padding(16)
        }
        .frame(minWidth: 300, idealWidth: 320, maxWidth: 360)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AnimateDex")
                .font(.title2.bold())
            Text("Import, inspect, apply Motion Recipes, and render proof MP4s.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var projectActions: some View {
        GroupBox("Project Actions") {
            VStack(alignment: .leading, spacing: 8) {
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

                Button("Render Proof MP4") {
                    appModel.renderProject()
                }
                .disabled(!appModel.hasActiveProject || appModel.scenes.isEmpty)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var projectSummary: some View {
        GroupBox("Project Summary") {
            VStack(alignment: .leading, spacing: 8) {
                summaryRow("Project", appModel.activeProject?.projectName ?? "No project open")
                summaryRow("Scenes", "\(appModel.scenes.count)")
                summaryRow("Validation", "\(appModel.validationIssues.count)")
                summaryRow("Workspace", appModel.workspaceShortSummary)

                if let activeProject = appModel.activeProject {
                    PathRow(title: "Path", value: activeProject.workspacePath, action: appModel.copyWorkspacePath)
                } else {
                    Text("Import an image folder or ZIP, or open an existing .animdex workspace.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var workflowNavigation: some View {
        GroupBox("Workflow") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(AppWorkflowSection.allCases) { section in
                    Button {
                        appModel.selectedSection = section
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: section.symbolName)
                                .frame(width: 20, alignment: .leading)
                            Text(section.title)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statusCard: some View {
        NoticeCard(
            title: "Status",
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
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 82, alignment: .leading)
            Text(value)
                .lineLimit(2)
        }
    }
}

private struct PathRow: View {
    let title: String
    let value: String
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                if let action {
                    Button("Copy", action: action)
                        .buttonStyle(.borderless)
                }
            }
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(2)
                .textSelection(.enabled)
        }
    }
}

struct NoticeCard: View {
    let title: String
    let notice: AppNotice
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        GroupBox(title) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(notice.summary)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button(actionTitle, action: action)
                        .buttonStyle(.bordered)
                }

                Text(notice.details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let path = notice.path, !path.isEmpty {
                    PathRow(title: "Path", value: path)
                }

                if let suggestion = notice.suggestion, !suggestion.isEmpty {
                    Text("Next: \(suggestion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

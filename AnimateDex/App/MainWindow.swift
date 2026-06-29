import SwiftUI

struct MainWindow: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            ProjectOpenView(appModel: appModel)
        } detail: {
            if appModel.activeProject != nil {
                DashboardView(appModel: appModel)
            } else {
                ContentUnavailableView(
                    "No Project Open",
                    systemImage: "film",
                    description: Text("Create a project or open an existing .animdex workspace.")
                )
            }
        }
        .frame(minWidth: 1200, minHeight: 780)
        .task {
            await appModel.runAutomationIfConfigured()
        }
    }
}

struct DashboardView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 14) {
                    ImportView(appModel: appModel)
                    ValidationIssuesView(issues: appModel.validationIssues)
                    SequenceBrowserView(scenes: appModel.scenes, selectedSceneID: $appModel.selectedSceneID)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 14) {
                    SceneInspectorView(appModel: appModel)
                    RenderSettingsView(renderSettings: $appModel.renderSettings)
                    MotionRecipeView(appModel: appModel)
                    RenderProgressView(
                        statusMessage: appModel.statusMessage,
                        progressValue: appModel.renderProgress,
                        renderLog: appModel.renderLog
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appModel.activeProject?.projectName ?? "AnimateDex")
                    .font(.title.bold())
                Text(appModel.workspaceSummary)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open Exports Folder") {
                appModel.openExportsFolder()
            }
            .disabled(!appModel.hasActiveProject)
        }
    }
}

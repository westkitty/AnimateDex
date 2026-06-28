import SwiftUI

struct ProjectOpenView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AnimateDex")
                .font(.largeTitle.bold())
            Text("Build deterministic animated video drafts from image folders or ZIP archives.")
                .foregroundStyle(.secondary)

            GroupBox("Project Actions") {
                VStack(alignment: .leading, spacing: 8) {
                    Button("New Project") { appModel.createNewProject() }
                    Button("Open Existing Project") { appModel.openExistingProject() }
                    Button("Import Folder or ZIP") { appModel.importFolderOrZip() }
                        .disabled(!appModel.hasActiveProject)
                    Button("Render Proof MP4") { appModel.renderProject() }
                        .disabled(!appModel.hasActiveProject || appModel.scenes.isEmpty)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Project Status") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Status: \(appModel.statusMessage)")
                    Text("Scenes: \(appModel.scenes.count)")
                    Text("Validation issues: \(appModel.validationIssues.count)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding(16)
        .frame(minWidth: 260)
    }
}

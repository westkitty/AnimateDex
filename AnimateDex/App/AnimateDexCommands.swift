import SwiftUI

struct AnimateDexCommands: Commands {
    @Bindable var appModel: AppViewModel

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Empty Project") {
                appModel.createNewProject()
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button("Import Folder or ZIP...") {
                appModel.importFolderOrZip()
            }
            .keyboardShortcut("i", modifiers: [.command])

            Button("Open Existing Project...") {
                appModel.openExistingProject()
            }
            .keyboardShortcut("o", modifiers: [.command])

            Divider()

            Button("Reveal Workspace in Finder") {
                appModel.revealWorkspaceInFinder()
            }
            .disabled(!appModel.hasActiveProject)

            Button("Reveal Exports in Finder") {
                appModel.revealExportsInFinder()
            }
            .disabled(!appModel.hasActiveProject)
        }

        CommandMenu("Workflow") {
            workflowButton("Show Overview", .overview, shortcut: "1")
            workflowButton("Show Sequence", .sequence, shortcut: "2")
            workflowButton("Show Motion Recipe", .motionRecipe, shortcut: "3")
            workflowButton("Show Render", .render, shortcut: "4")
            workflowButton("Show Diagnostics", .diagnostics, shortcut: "5")
        }

        CommandMenu("Render") {
            Button("Render Proof MP4") {
                appModel.renderProject()
            }
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(!appModel.hasActiveProject || appModel.scenes.isEmpty)

            Button("Reveal Last Render") {
                appModel.revealLastRender()
            }
            .disabled(appModel.renderOutputPath == nil)
        }

        CommandMenu("Diagnostics") {
            Button("Copy Diagnostics") {
                appModel.copyDiagnostics()
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])

            Button("Copy Last Error") {
                appModel.copyLastError()
            }
            .disabled(appModel.lastErrorNotice == nil)
        }
    }

    private func workflowButton(_ title: String, _ section: AppWorkflowSection, shortcut: String) -> some View {
        Button(title) {
            appModel.showSection(section)
        }
        .keyboardShortcut(KeyEquivalent(shortcut.first ?? "1"), modifiers: [.command])
    }
}

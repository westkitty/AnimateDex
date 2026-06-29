import SwiftUI

struct MainWindow: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            AppSidebarView(appModel: appModel)
        } detail: {
            WorkspaceDetailView(appModel: appModel)
        }
        .frame(minWidth: 1100, minHeight: 720)
        .task {
            await appModel.runAutomationIfConfigured()
        }
    }
}

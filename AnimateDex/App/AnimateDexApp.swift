import SwiftUI
import AppKit

@main
struct AnimateDexApp: App {
    @State private var appModel = AppViewModel()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup("AnimateDex") {
            MainWindow(appModel: appModel)
        }
        .windowStyle(.automatic)
        .commands {
            AnimateDexCommands(appModel: appModel)
        }
    }
}

import SwiftUI

@main
struct AnimateDexApp: App {
    @State private var appModel = AppViewModel()

    var body: some Scene {
        WindowGroup("AnimateDex") {
            MainWindow(appModel: appModel)
        }
        .windowStyle(.automatic)
    }
}

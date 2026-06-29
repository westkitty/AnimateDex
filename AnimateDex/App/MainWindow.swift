import SwiftUI
import AppKit

struct MainWindow: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        NavigationSplitView {
            AppSidebarView(appModel: appModel)
        } detail: {
            WorkspaceDetailView(appModel: appModel)
        }
        .frame(minWidth: 900, minHeight: 620)
        .background(WindowConfigurator(minSize: NSSize(width: 900, height: 620)))
        .task {
            await appModel.runAutomationIfConfigured()
        }
    }
}

private struct WindowConfigurator: NSViewRepresentable {
    let minSize: NSSize

    func makeNSView(context: Context) -> WindowAccessorView {
        WindowAccessorView(minSize: minSize)
    }

    func updateNSView(_ nsView: WindowAccessorView, context: Context) {
        nsView.minSize = minSize
        nsView.configureWindowIfNeeded()
    }
}

private final class WindowAccessorView: NSView {
    var minSize: NSSize
    private var didConfigureWindow = false

    init(minSize: NSSize) {
        self.minSize = minSize
        super.init(frame: .zero)
        wantsLayer = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindowIfNeeded()
    }

    func configureWindowIfNeeded() {
        guard let window, !didConfigureWindow else { return }
        didConfigureWindow = true
        window.styleMask.insert(.resizable)
        window.minSize = minSize
    }
}

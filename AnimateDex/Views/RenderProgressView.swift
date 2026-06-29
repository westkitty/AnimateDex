import SwiftUI

struct RenderProgressView: View {
    let statusMessage: String
    let statusDetails: String
    let progressValue: Double
    let renderLog: String
    let outputPath: String?
    let renderLogPath: String
    let copyLogAction: () -> Void
    let openExportsAction: () -> Void

    var body: some View {
        GroupBox("Render Output") {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: progressValue)
                Text(statusMessage)
                    .font(.headline)
                Text(statusDetails)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    if let outputPath {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Output")
                                .foregroundStyle(.secondary)
                            Text(outputPath)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    Button("Copy Log") {
                        copyLogAction()
                    }
                    .disabled(renderLog.isEmpty)
                    Button("Open Exports") {
                        openExportsAction()
                    }
                    .disabled(outputPath == nil)
                }
                if !renderLogPath.isEmpty {
                    Text("Log path: \(renderLogPath)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                ScrollView {
                    Text(renderLog.isEmpty ? "No render log yet." : renderLog)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 180, maxHeight: 260)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

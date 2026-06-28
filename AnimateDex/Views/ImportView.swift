import SwiftUI

struct ImportView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        GroupBox("Import") {
            VStack(alignment: .leading, spacing: 8) {
                Text(appModel.importReport.map { "Imported \($0.supportedFileCount) usable images." } ?? "No import report yet.")
                if let report = appModel.importReport, !report.unsupportedFiles.isEmpty {
                    Text("Unsupported: \(report.unsupportedFiles.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Button("Import Folder or ZIP") {
                        appModel.importFolderOrZip()
                    }
                    Button("Render") {
                        appModel.renderProject()
                    }
                    .disabled(appModel.scenes.isEmpty)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

import SwiftUI

struct RenderProgressView: View {
    let statusMessage: String
    let progressValue: Double
    let renderLog: String

    var body: some View {
        GroupBox("Render Output") {
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: progressValue)
                Text(statusMessage)
                ScrollView {
                    Text(renderLog.isEmpty ? "No render log yet." : renderLog)
                        .font(.system(.footnote, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 180)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

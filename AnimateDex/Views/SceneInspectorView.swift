import SwiftUI

struct SceneInspectorView: View {
    let scene: SceneItem?

    var body: some View {
        GroupBox("Scene Inspector") {
            if let scene {
                VStack(alignment: .leading, spacing: 8) {
                    Text(scene.filename)
                        .font(.headline)
                    detailRow("Sequence", "\(scene.sequenceIndex)")
                    detailRow("Size", "\(scene.width) x \(scene.height)")
                    detailRow("File size", "\(scene.fileSizeBytes) bytes")
                    detailRow("Preset", scene.motionPreset.rawValue)
                    detailRow("Orientation", scene.orientation.rawValue)
                    detailRow("Validation", scene.validationStatus)
                    if !scene.validationIssues.isEmpty {
                        ForEach(scene.validationIssues) { issue in
                            Text("• \(issue.message)")
                                .font(.footnote)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Select a scene to inspect it.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .frame(width: 90, alignment: .leading)
                .foregroundStyle(.secondary)
            Text(value)
        }
    }
}

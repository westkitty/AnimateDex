import SwiftUI

struct SceneInspectorView: View {
    @Bindable var appModel: AppViewModel

    var body: some View {
        GroupBox("Scene Inspector") {
            if let scene = appModel.selectedScene {
                VStack(alignment: .leading, spacing: 8) {
                    Text(scene.filename)
                        .font(.headline)
                    detailRow("Sequence", "\(scene.sequenceIndex)")
                    detailRow("Size", "\(scene.width) x \(scene.height)")
                    detailRow("File size", "\(scene.fileSizeBytes) bytes")
                    detailRow("Orientation", scene.orientation.rawValue)
                    detailRow("Validation", scene.validationStatus)
                    Picker("Preset", selection: presetBinding(for: scene)) {
                        ForEach(MotionPreset.allCases) { preset in
                            Text(preset.displayName).tag(preset)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: 260, alignment: .leading)
                    Text(scene.motionPreset.shortDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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

    private func presetBinding(for scene: SceneItem) -> Binding<MotionPreset> {
        Binding(
            get: { scene.motionPreset },
            set: { newValue in
                appModel.updateScenePreset(sceneID: scene.id, preset: newValue)
            }
        )
    }
}

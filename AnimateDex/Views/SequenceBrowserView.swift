import SwiftUI

struct SequenceBrowserView: View {
    let scenes: [SceneItem]
    @Binding var selectedSceneID: String?

    var body: some View {
        GroupBox("Sequence Browser") {
            List(scenes, selection: $selectedSceneID) { scene in
                VStack(alignment: .leading, spacing: 3) {
                    Text(scene.filename)
                    Text("#\(scene.sequenceIndex)  \(scene.width)x\(scene.height)  \(scene.motionPreset.displayName)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .tag(scene.id)
            }
            .frame(minHeight: 220)
        }
    }
}

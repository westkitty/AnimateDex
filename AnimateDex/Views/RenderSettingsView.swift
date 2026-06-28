import SwiftUI

struct RenderSettingsView: View {
    @Binding var renderSettings: RenderSettings

    var body: some View {
        GroupBox("Render Settings") {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                row("Width", value: $renderSettings.outputWidth)
                row("Height", value: $renderSettings.outputHeight)
                row("FPS", value: $renderSettings.fps)
                row("Scene Duration", value: $renderSettings.defaultSceneDuration)
                row("Transition Duration", value: $renderSettings.transitionDuration)
                row("Filename", value: $renderSettings.outputFilename)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func row(_ label: String, value: Binding<Int>) -> some View {
        GridRow {
            Text(label)
            TextField("", value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
        }
    }

    private func row(_ label: String, value: Binding<Double>) -> some View {
        GridRow {
            Text(label)
            TextField("", value: value, format: .number.precision(.fractionLength(2)))
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
        }
    }

    private func row(_ label: String, value: Binding<String>) -> some View {
        GridRow {
            Text(label)
            TextField("", text: value)
                .textFieldStyle(.roundedBorder)
                .frame(width: 220)
        }
    }
}

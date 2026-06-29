import Foundation

struct AIPromptBriefService {
    func makePromptBrief(project: AnimateProject, scenes: [SceneItem], renderSettings: RenderSettings) -> String {
        let sortedScenes = scenes.sorted { $0.sequenceIndex < $1.sequenceIndex }
        let dimensionSummary = summarizeDimensions(scenes: sortedScenes)
        let orientationSummary = summarizeOrientations(scenes: sortedScenes)
        let irregularScenes = sortedScenes.filter {
            $0.differsFromDominantSize || $0.validationStatus != "ok" || !$0.validationIssues.isEmpty
        }

        var lines: [String] = []
        lines.append("AnimateDex Motion Recipe Brief")
        lines.append("Return a single JSON object only. Do not add markdown fences, prose, or code comments.")
        lines.append("Use schemaVersion = 1 and target.matchMode = \"sequenceIndex\".")
        lines.append("")
        lines.append("Project")
        lines.append("- Name: \(project.projectName)")
        lines.append("- Workspace: \(project.workspacePath)")
        lines.append("- Scene count: \(sortedScenes.count)")
        lines.append("- Sequence range: \(sequenceRange(scenes: sortedScenes))")
        lines.append("")
        lines.append("Current render settings")
        lines.append("- Output: \(renderSettings.outputWidth)x\(renderSettings.outputHeight)")
        lines.append("- FPS: \(renderSettings.fps)")
        lines.append("- Default scene duration: \(renderSettings.defaultSceneDuration)")
        lines.append("- Transition duration: \(renderSettings.transitionDuration)")
        lines.append("- Output filename: \(renderSettings.outputFilename)")
        lines.append("")
        lines.append("Scene distribution")
        lines.append("- Dimensions: \(dimensionSummary)")
        lines.append("- Orientation: \(orientationSummary)")
        if irregularScenes.isEmpty {
            lines.append("- Irregular scenes: none detected")
        } else {
            lines.append("- Irregular scenes:")
            lines.append(contentsOf: irregularScenes.prefix(12).map { scene in
                "- #\(scene.sequenceIndex) \(scene.filename) [\(scene.width)x\(scene.height), \(scene.validationStatus)]"
            })
        }
        lines.append("")
        lines.append("Supported motion presets")
        lines.append("- " + MotionPreset.allCases.map { "\($0.rawValue) (\($0.displayName))" }.joined(separator: ", "))
        lines.append("- Use locked_off, gentle_drift, or problem_insert for unstable or irregular assets.")
        lines.append("")
        lines.append("Recipe guidance")
        lines.append("- Keep durations positive.")
        lines.append("- Use sections for contiguous runs of scenes.")
        lines.append("- Use sceneOverrides only for explicit exceptions.")
        lines.append("- Unknown fields will be ignored by AnimateDex.")
        lines.append("- Return no more than one recipe object.")
        return lines.joined(separator: "\n")
    }

    private func sequenceRange(scenes: [SceneItem]) -> String {
        guard let first = scenes.first, let last = scenes.last else {
            return "empty"
        }
        return "\(first.sequenceIndex)-\(last.sequenceIndex)"
    }

    private func summarizeDimensions(scenes: [SceneItem]) -> String {
        guard !scenes.isEmpty else { return "none" }
        let grouped = Dictionary(grouping: scenes, by: { "\($0.width)x\($0.height)" })
        return grouped.keys.sorted().map { "\($0) (\(grouped[$0]?.count ?? 0))" }.joined(separator: ", ")
    }

    private func summarizeOrientations(scenes: [SceneItem]) -> String {
        guard !scenes.isEmpty else { return "none" }
        let grouped = Dictionary(grouping: scenes, by: { $0.orientation.rawValue })
        return grouped.keys.sorted().map { "\($0) (\(grouped[$0]?.count ?? 0))" }.joined(separator: ", ")
    }
}

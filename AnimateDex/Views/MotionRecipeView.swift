import SwiftUI

struct MotionRecipeView: View {
    @Bindable var appModel: AppViewModel

    private var validationResult: MotionRecipeValidationResult? {
        appModel.motionRecipeValidationResult
    }

    private var canApply: Bool {
        guard appModel.hasActiveProject else { return false }
        guard let result = validationResult, let recipe = result.recipe else { return false }
        return !result.hasErrors && !recipe.recipeName.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            toolbar
            recipeEditor
            statusBlock
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Motion Recipe")
                    .font(.headline)
                Spacer()
                Text(appModel.motionRecipeStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Paste deterministic recipe JSON, validate it against the current scene plan, preview the affected scenes, then apply it to the workspace.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            Menu("Load Example") {
                ForEach(MotionRecipeExample.allCases) { example in
                    Button(example.title) {
                        appModel.loadMotionRecipeExample(example)
                    }
                }
            }

            Button("Copy AI Prompt Brief") {
                appModel.copyAIPromptBrief()
            }
            .disabled(!appModel.hasActiveProject)

            Button("Validate") {
                appModel.validateMotionRecipe()
            }

            Button("Preview Changes") {
                appModel.previewMotionRecipe()
            }

            Button("Apply Recipe") {
                appModel.applyMotionRecipe()
            }
            .disabled(!canApply)

            Button("Clear") {
                appModel.clearMotionRecipe()
            }
        }
        .buttonStyle(.bordered)
    }

    private var recipeEditor: some View {
        TextEditor(text: $appModel.motionRecipeText)
            .font(.system(.body, design: .monospaced))
            .frame(minHeight: 220)
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.2))
            )
    }

    @ViewBuilder
    private var statusBlock: some View {
        if let validationResult {
            VStack(alignment: .leading, spacing: 10) {
                summaryRow(title: "Validation", subtitle: validationSummary(validationResult))
                issueList(title: "Issues", issues: validationResult.issues)
                if !validationResult.ignoredFields.isEmpty {
                    labeledList(
                        title: "Ignored fields",
                        values: validationResult.ignoredFields
                    )
                }
            }
        }

        if let preview = appModel.motionRecipePreview {
            VStack(alignment: .leading, spacing: 10) {
                summaryRow(
                    title: "Preview",
                    subtitle: "\(preview.affectedSceneCount) of \(preview.totalScenes) scenes affected"
                )
                previewMetrics(preview)
                if !preview.globalRenderSettingChanges.isEmpty {
                    labeledList(title: "Render setting changes", values: preview.globalRenderSettingChanges)
                }
                if !preview.affectedScenes.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("First affected scenes")
                            .font(.subheadline.weight(.semibold))
                        ForEach(preview.affectedScenes) { scene in
                            VStack(alignment: .leading, spacing: 2) {
                                Text("#\(scene.sequenceIndex) \(scene.filename)")
                                    .font(.caption.weight(.semibold))
                                Text("Duration \(scene.beforeDuration, specifier: "%.2f") -> \(scene.afterDuration, specifier: "%.2f"), \(scene.beforeMotionPreset.rawValue) -> \(scene.afterMotionPreset.rawValue), transitions \(scene.beforeTransitionIn) / \(scene.beforeTransitionOut) -> \(scene.afterTransitionIn) / \(scene.afterTransitionOut)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }

        if let result = appModel.motionRecipeApplicationResult {
            VStack(alignment: .leading, spacing: 10) {
                summaryRow(
                    title: "Applied",
                    subtitle: "\(result.changedSceneCount) changed scene(s), \(result.affectedSceneCount) affected scene(s)"
                )
                labeledList(
                    title: "Files written",
                    values: [
                        result.backupPath,
                        result.appliedRecipePath,
                        result.reportPath,
                        result.outputScenePlanPath
                    ]
                )
                if !result.warnings.isEmpty {
                    labeledList(title: "Warnings", values: result.warnings)
                }
            }
        }
    }

    private func validationSummary(_ result: MotionRecipeValidationResult) -> String {
        let errors = result.issues.filter { $0.severity == .error }.count
        let warnings = result.issues.filter { $0.severity == .warning }.count
        let info = result.issues.filter { $0.severity == .info }.count
        return "\(errors) error(s), \(warnings) warning(s), \(info) info item(s)"
    }

    private func summaryRow(title: String, subtitle: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func issueList(title: String, issues: [MotionRecipeValidationIssue]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            if issues.isEmpty {
                Text("No validation issues.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(issues) { issue in
                    HStack(alignment: .top, spacing: 8) {
                        Text(issue.severity.rawValue.uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(color(for: issue.severity))
                            .frame(width: 54, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(issue.message)
                                .font(.caption)
                            Text(issue.code)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func labeledList(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            ForEach(values, id: \.self) { value in
                Text("• \(value)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private func previewMetrics(_ preview: MotionRecipePreview) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recipe: \(preview.recipeName)")
                .font(.caption.weight(.semibold))
            Text(preview.description)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Sections: \(preview.sectionCount), overrides: \(preview.overrideCount), durations: \(preview.durationChangesCount), motion presets: \(preview.motionPresetChangesCount), transitions: \(preview.transitionChangesCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func color(for severity: MotionRecipeValidationSeverity) -> Color {
        switch severity {
        case .error:
            .red
        case .warning:
            .orange
        case .info:
            .blue
        }
    }
}

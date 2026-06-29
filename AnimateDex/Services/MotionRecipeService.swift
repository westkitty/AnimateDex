import Foundation

struct MotionRecipeService {
    private let workspaceService = WorkspaceService()
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder
    }

    func validate(recipeText: String, currentScenes: [SceneItem], project: AnimateProject?) -> MotionRecipeValidationResult {
        let trimmed = recipeText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return MotionRecipeValidationResult(
                recipe: nil,
                issues: [
                    MotionRecipeValidationIssue(
                        severity: .error,
                        code: "empty_recipe",
                        message: "Paste a Motion Recipe JSON object before validating."
                    )
                ],
                ignoredFields: []
            )
        }

        guard let data = trimmed.data(using: .utf8) else {
            return MotionRecipeValidationResult(
                recipe: nil,
                issues: [
                    MotionRecipeValidationIssue(
                        severity: .error,
                        code: "invalid_text_encoding",
                        message: "The pasted text could not be converted to UTF-8."
                    )
                ],
                ignoredFields: []
            )
        }

        let ignoredFields = ignoredRecipeFields(from: data)

        do {
            let recipe = try decoder.decode(MotionRecipe.self, from: data)
            let issues = validate(recipe: recipe, currentScenes: currentScenes, project: project, ignoredFields: ignoredFields)
            return MotionRecipeValidationResult(recipe: recipe, issues: issues, ignoredFields: ignoredFields)
        } catch {
            return MotionRecipeValidationResult(
                recipe: nil,
                issues: [
                    MotionRecipeValidationIssue(
                        severity: .error,
                        code: "malformed_json",
                        message: parseErrorMessage(for: error)
                    )
                ],
                ignoredFields: ignoredFields
            )
        }
    }

    func preview(recipe: MotionRecipe, currentScenes: [SceneItem], project: AnimateProject?) -> MotionRecipePreview {
        let evaluation = evaluate(recipe: recipe, currentScenes: currentScenes, project: project)
        return MotionRecipePreview(
            recipeName: recipe.recipeName,
            description: recipe.description,
            totalScenes: currentScenes.count,
            affectedSceneCount: evaluation.affectedScenes.count,
            globalRenderSettingChanges: evaluation.globalRenderSettingChanges,
            sectionCount: recipe.sections.count,
            overrideCount: recipe.sceneOverrides.count,
            durationChangesCount: evaluation.durationChangesCount,
            motionPresetChangesCount: evaluation.motionPresetChangesCount,
            transitionChangesCount: evaluation.transitionChangesCount,
            validationIssues: evaluation.issues,
            affectedScenes: Array(evaluation.affectedScenes.prefix(10))
        )
    }

    func apply(
        recipe: MotionRecipe,
        project: AnimateProject,
        currentScenes: [SceneItem],
        importReport: ImportReport?,
        workspaceURL: URL
    ) throws -> MotionRecipeApplicationResult {
        let evaluation = evaluate(recipe: recipe, currentScenes: currentScenes, project: project)
        let blockingIssues = evaluation.issues.filter { $0.severity == .error }
        if !blockingIssues.isEmpty {
            throw NSError(
                domain: "AnimateDex.MotionRecipe",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: blockingIssues.map(\.message).joined(separator: "\n")]
            )
        }

        let scenePlanURL = workspaceURL.appendingPathComponent("scene_plan.json")
        guard FileManager.default.fileExists(atPath: scenePlanURL.path) else {
            throw NSError(
                domain: "AnimateDex.MotionRecipe",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Current scene_plan.json is missing."]
            )
        }

        let backupURL = workspaceURL.appendingPathComponent("scene_plan.before_motion_recipe.json")
        if FileManager.default.fileExists(atPath: backupURL.path) {
            try FileManager.default.removeItem(at: backupURL)
        }
        try FileManager.default.copyItem(at: scenePlanURL, to: backupURL)

        var updatedProject = project
        updatedProject.updatedAt = .now
        updatedProject.renderSettings = mergedRenderSettings(project.renderSettings, recipe.globalRenderSettings)
        updatedProject.lastMotionRecipeName = recipe.recipeName

        try workspaceService.save(
            project: updatedProject,
            scenes: evaluation.updatedScenes,
            importReport: importReport,
            to: workspaceURL
        )

        let appliedRecipeURL = workspaceURL.appendingPathComponent("motion_recipe_applied.json")
        let appliedRecipeData = try encoder.encode(recipe)
        try appliedRecipeData.write(to: appliedRecipeURL, options: .atomic)

        let reportURL = workspaceURL.appendingPathComponent("motion_recipe_report.txt")
        let reportText = makeReport(
            recipe: recipe,
            evaluation: evaluation,
            backupPath: backupURL.path,
            appliedRecipePath: appliedRecipeURL.path,
            outputScenePlanPath: scenePlanURL.path
        )
        guard let reportData = reportText.data(using: .utf8) else {
            throw NSError(
                domain: "AnimateDex.MotionRecipe",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Motion recipe report could not be encoded as UTF-8."]
            )
        }
        try reportData.write(to: reportURL, options: .atomic)

        return MotionRecipeApplicationResult(
            recipeName: recipe.recipeName,
            affectedSceneCount: evaluation.affectedScenes.count,
            changedSceneCount: evaluation.changedScenesCount,
            backupPath: backupURL.path,
            appliedRecipePath: appliedRecipeURL.path,
            reportPath: reportURL.path,
            outputScenePlanPath: scenePlanURL.path,
            warnings: evaluation.issues.filter { $0.severity != .error }.map(\.message),
            ignoredFields: evaluation.ignoredFields
        )
    }

    private func validate(
        recipe: MotionRecipe,
        currentScenes: [SceneItem],
        project: AnimateProject?,
        ignoredFields: [String]
    ) -> [MotionRecipeValidationIssue] {
        var issues: [MotionRecipeValidationIssue] = []

        if recipe.schemaVersion != 1 {
            issues.append(issue(.error, "unsupported_schema_version", "schemaVersion \(recipe.schemaVersion) is not supported."))
        }

        if recipe.recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(issue(.warning, "missing_recipe_name", "No recipeName was provided; using the pasted JSON as-is."))
        }

        if currentScenes.isEmpty || project == nil {
            issues.append(issue(.error, "no_loaded_scene_plan", "Load a project with a scene plan before applying a recipe."))
        }

        if recipe.target.matchMode != "sequenceIndex" {
            issues.append(issue(.error, "unsupported_target_match_mode", "Only matchMode=\"sequenceIndex\" is supported in this build."))
        }

        validateRange(recipe.target.sceneRange, code: "target_range", label: "Target scene range", issues: &issues)

        if let currentRange = currentScenesSequenceRange(currentScenes) {
            if !rangesOverlap(recipe.target.sceneRange, currentRange) {
                issues.append(issue(.error, "target_out_of_range", "The target scene range does not intersect the current scene plan."))
            }
        }

        if recipe.globalRenderSettings.outputWidth <= 0 {
            issues.append(issue(.error, "invalid_output_width", "outputWidth must be greater than zero."))
        }
        if recipe.globalRenderSettings.outputHeight <= 0 {
            issues.append(issue(.error, "invalid_output_height", "outputHeight must be greater than zero."))
        }
        if recipe.globalRenderSettings.fps <= 0 {
            issues.append(issue(.error, "invalid_fps", "fps must be greater than zero."))
        }
        if recipe.globalRenderSettings.defaultSceneDuration <= 0 {
            issues.append(issue(.error, "invalid_default_scene_duration", "defaultSceneDuration must be greater than zero."))
        }
        if recipe.globalDefaults.durationSeconds <= 0 {
            issues.append(issue(.error, "invalid_default_duration", "globalDefaults.durationSeconds must be greater than zero."))
        }

        for section in recipe.sections {
            validateRange(section.sceneRange, code: "section_range_\(section.name)", label: "Section \(section.name)", issues: &issues)
            if section.durationSeconds <= 0 {
                issues.append(issue(.error, "invalid_section_duration_\(section.name)", "Section \(section.name) has a non-positive duration."))
            }
        }

        if hasOverlappingSections(recipe.sections) {
            issues.append(issue(.warning, "overlapping_sections", "Sections overlap; later sections will win where they intersect."))
        }

        for override in recipe.sceneOverrides {
            if override.durationSeconds <= 0 {
                issues.append(issue(.error, "invalid_override_duration_\(override.sequenceIndex)", "Scene override \(override.sequenceIndex) has a non-positive duration."))
            }
            if !currentScenes.contains(where: { $0.sequenceIndex == override.sequenceIndex }) {
                issues.append(issue(.error, "missing_override_scene_\(override.sequenceIndex)", "Scene override \(override.sequenceIndex) does not match a loaded scene."))
            }
            if let sceneId = override.sceneId?.trimmingCharacters(in: .whitespacesAndNewlines), !sceneId.isEmpty {
                issues.append(issue(.info, "ignored_optional_scene_id_\(override.sequenceIndex)", "sceneId was parsed and ignored in this MVP build."))
            }
            if let contains = override.filenameContains?.trimmingCharacters(in: .whitespacesAndNewlines), !contains.isEmpty {
                issues.append(issue(.info, "ignored_optional_filename_contains_\(override.sequenceIndex)", "filenameContains was parsed and ignored in this MVP build."))
            }
        }

        for field in ignoredFields {
            issues.append(issue(.info, "ignored_field_\(sanitizeCode(field))", "Ignored future field \(field)."))
        }

        return issues
    }

    private struct Evaluation {
        var updatedScenes: [SceneItem]
        var affectedScenes: [MotionRecipePreviewSceneChange]
        var globalRenderSettingChanges: [String]
        var durationChangesCount: Int
        var motionPresetChangesCount: Int
        var transitionChangesCount: Int
        var changedScenesCount: Int
        var issues: [MotionRecipeValidationIssue]
        var ignoredFields: [String]
    }

    private func evaluate(recipe: MotionRecipe, currentScenes: [SceneItem], project: AnimateProject?) -> Evaluation {
        let issues = validate(recipe: recipe, currentScenes: currentScenes, project: project, ignoredFields: [])
        let blockingIssues = issues.filter { $0.severity == .error }
        guard blockingIssues.isEmpty else {
            return Evaluation(
                updatedScenes: currentScenes,
                affectedScenes: [],
                globalRenderSettingChanges: [],
                durationChangesCount: 0,
                motionPresetChangesCount: 0,
                transitionChangesCount: 0,
                changedScenesCount: 0,
                issues: issues,
                ignoredFields: []
            )
        }

        var updatedScenes = currentScenes
        let targetIndexes = Set(currentScenes
            .filter { recipe.target.sceneRange.start...recipe.target.sceneRange.end ~= $0.sequenceIndex }
            .map(\.sequenceIndex))

        for index in updatedScenes.indices {
            guard targetIndexes.contains(updatedScenes[index].sequenceIndex) else { continue }
            apply(defaults: recipe.globalDefaults, to: &updatedScenes[index])
        }

        for section in recipe.sections {
            for index in updatedScenes.indices {
                guard targetIndexes.contains(updatedScenes[index].sequenceIndex) else { continue }
                guard section.sceneRange.start...section.sceneRange.end ~= updatedScenes[index].sequenceIndex else { continue }
                apply(section: section, to: &updatedScenes[index])
            }
        }

        for override in recipe.sceneOverrides {
            guard let index = updatedScenes.firstIndex(where: { $0.sequenceIndex == override.sequenceIndex }) else { continue }
            apply(override: override, to: &updatedScenes[index])
        }

        let affectedScenes = buildAffectedScenes(before: currentScenes, after: updatedScenes, recipe: recipe)
        let changes = changeCounts(before: currentScenes, after: updatedScenes)
        let globalChanges = renderSettingChanges(before: project?.renderSettings, after: mergedRenderSettings(project?.renderSettings ?? .default, recipe.globalRenderSettings))

        return Evaluation(
            updatedScenes: updatedScenes,
            affectedScenes: affectedScenes,
            globalRenderSettingChanges: globalChanges,
            durationChangesCount: changes.duration,
            motionPresetChangesCount: changes.motionPreset,
            transitionChangesCount: changes.transition,
            changedScenesCount: changes.changedScenes,
            issues: issues,
            ignoredFields: []
        )
    }

    private func buildAffectedScenes(before: [SceneItem], after: [SceneItem], recipe: MotionRecipe) -> [MotionRecipePreviewSceneChange] {
        let beforeByIndex = Dictionary(uniqueKeysWithValues: before.map { ($0.sequenceIndex, $0) })
        return after.compactMap { scene in
            guard let original = beforeByIndex[scene.sequenceIndex] else { return nil }
            guard original.durationSeconds != scene.durationSeconds ||
                    original.motionPreset != scene.motionPreset ||
                    original.transitionIn != scene.transitionIn ||
                    original.transitionOut != scene.transitionOut else {
                return nil
            }
            return MotionRecipePreviewSceneChange(
                sequenceIndex: scene.sequenceIndex,
                filename: scene.filename,
                beforeDuration: original.durationSeconds,
                afterDuration: scene.durationSeconds,
                beforeMotionPreset: original.motionPreset,
                afterMotionPreset: scene.motionPreset,
                beforeTransitionIn: original.transitionIn,
                afterTransitionIn: scene.transitionIn,
                beforeTransitionOut: original.transitionOut,
                afterTransitionOut: scene.transitionOut
            )
        }
        .prefix(10)
        .map { $0 }
    }

    private func changeCounts(before: [SceneItem], after: [SceneItem]) -> (duration: Int, motionPreset: Int, transition: Int, changedScenes: Int) {
        let beforeByIndex = Dictionary(uniqueKeysWithValues: before.map { ($0.sequenceIndex, $0) })
        var duration = 0
        var motionPreset = 0
        var transition = 0
        var changedScenes = 0

        for scene in after {
            guard let original = beforeByIndex[scene.sequenceIndex] else { continue }
            var changed = false
            if original.durationSeconds != scene.durationSeconds {
                duration += 1
                changed = true
            }
            if original.motionPreset != scene.motionPreset {
                motionPreset += 1
                changed = true
            }
            if original.transitionIn != scene.transitionIn || original.transitionOut != scene.transitionOut {
                transition += 1
                changed = true
            }
            if changed {
                changedScenes += 1
            }
        }

        return (duration, motionPreset, transition, changedScenes)
    }

    private func renderSettingChanges(before: RenderSettings?, after: RenderSettings) -> [String] {
        let original = before ?? .default
        var changes: [String] = []
        if original.outputWidth != after.outputWidth {
            changes.append("outputWidth: \(original.outputWidth) -> \(after.outputWidth)")
        }
        if original.outputHeight != after.outputHeight {
            changes.append("outputHeight: \(original.outputHeight) -> \(after.outputHeight)")
        }
        if original.fps != after.fps {
            changes.append("fps: \(original.fps) -> \(after.fps)")
        }
        if original.defaultSceneDuration != after.defaultSceneDuration {
            changes.append("defaultSceneDuration: \(original.defaultSceneDuration) -> \(after.defaultSceneDuration)")
        }
        return changes
    }

    private func mergedRenderSettings(_ current: RenderSettings, _ recipeSettings: MotionRecipeGlobalRenderSettings) -> RenderSettings {
        var settings = current
        settings.outputWidth = recipeSettings.outputWidth
        settings.outputHeight = recipeSettings.outputHeight
        settings.fps = recipeSettings.fps
        settings.defaultSceneDuration = recipeSettings.defaultSceneDuration
        return settings
    }

    private func apply(defaults: MotionRecipeGlobalDefaults, to scene: inout SceneItem) {
        scene.durationSeconds = defaults.durationSeconds
        scene.motionPreset = defaults.motionPreset
        scene.transitionIn = defaults.transitionIn
        scene.transitionOut = defaults.transitionOut
    }

    private func apply(section: MotionRecipeSection, to scene: inout SceneItem) {
        scene.durationSeconds = section.durationSeconds
        scene.motionPreset = section.motionPreset
        scene.transitionIn = section.transitionIn
        scene.transitionOut = section.transitionOut
    }

    private func apply(override: MotionRecipeSceneOverride, to scene: inout SceneItem) {
        scene.durationSeconds = override.durationSeconds
        scene.motionPreset = override.motionPreset
        scene.transitionIn = override.transitionIn
        scene.transitionOut = override.transitionOut
        if !override.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scene.notes = override.notes
        }
    }

    private func validateRange(_ range: MotionRecipeSceneRange, code: String, label: String, issues: inout [MotionRecipeValidationIssue]) {
        if range.start <= 0 || range.end <= 0 {
            issues.append(issue(.error, "\(code)_positive", "\(label) must use positive scene indexes."))
        }
        if range.start > range.end {
            issues.append(issue(.error, "\(code)_order", "\(label) start must be less than or equal to end."))
        }
    }

    private func currentScenesSequenceRange(_ scenes: [SceneItem]) -> ClosedRange<Int>? {
        guard let start = scenes.map(\.sequenceIndex).min(),
              let end = scenes.map(\.sequenceIndex).max() else {
            return nil
        }
        return start...end
    }

    private func rangesOverlap(_ left: MotionRecipeSceneRange, _ right: ClosedRange<Int>) -> Bool {
        !(left.end < right.lowerBound || left.start > right.upperBound)
    }

    private func hasOverlappingSections(_ sections: [MotionRecipeSection]) -> Bool {
        guard sections.count > 1 else { return false }
        for index in sections.indices {
            let lhs = sections[index].sceneRange
            for otherIndex in sections.indices where otherIndex > index {
                let rhs = sections[otherIndex].sceneRange
                if !(lhs.end < rhs.start || lhs.start > rhs.end) {
                    return true
                }
            }
        }
        return false
    }

    private func issue(_ severity: MotionRecipeValidationSeverity, _ code: String, _ message: String) -> MotionRecipeValidationIssue {
        MotionRecipeValidationIssue(severity: severity, code: code, message: message)
    }

    private func parseErrorMessage(for error: Error) -> String {
        if let decodingError = error as? DecodingError {
            switch decodingError {
            case .dataCorrupted(let context):
                return "Malformed JSON: \(context.debugDescription)"
            case .keyNotFound(let key, let context):
                return "Missing required key '\(key.stringValue)': \(context.debugDescription)"
            case .typeMismatch(_, let context):
                return "Type mismatch: \(context.debugDescription)"
            case .valueNotFound(_, let context):
                return "Missing value: \(context.debugDescription)"
            @unknown default:
                return "Malformed JSON: \(decodingError.localizedDescription)"
            }
        }
        return "Malformed JSON: \(error.localizedDescription)"
    }

    private func ignoredRecipeFields(from data: Data) -> [String] {
        guard let root = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }
        return MotionRecipeFieldInspector().ignoredFields(in: root)
    }

    private func makeReport(recipe: MotionRecipe, evaluation: Evaluation, backupPath: String, appliedRecipePath: String, outputScenePlanPath: String) -> String {
        var lines: [String] = []
        lines.append("Motion Recipe Report")
        lines.append("Recipe: \(recipe.recipeName)")
        lines.append("Timestamp: \(ISO8601DateFormatter().string(from: .now))")
        lines.append("Scene count: \(evaluation.updatedScenes.count)")
        lines.append("Affected scene count: \(evaluation.affectedScenes.count)")
        lines.append("Changed scene count: \(evaluation.changedScenesCount)")
        lines.append("Global settings applied: \(evaluation.globalRenderSettingChanges.isEmpty ? "none" : evaluation.globalRenderSettingChanges.joined(separator: ", "))")
        lines.append("Sections applied: \(recipe.sections.count)")
        lines.append("Overrides applied: \(recipe.sceneOverrides.count)")
        lines.append("Warnings:")
        let warnings = evaluation.issues.filter { $0.severity != .error }
        if warnings.isEmpty {
            lines.append("- none")
        } else {
            lines.append(contentsOf: warnings.map { "- \($0.message)" })
        }
        if evaluation.ignoredFields.isEmpty {
            lines.append("Ignored fields: none")
        } else {
            lines.append("Ignored fields:")
            lines.append(contentsOf: evaluation.ignoredFields.map { "- \($0)" })
        }
        lines.append("Backup path: \(backupPath)")
        lines.append("Applied recipe path: \(appliedRecipePath)")
        lines.append("Output scene plan path: \(outputScenePlanPath)")
        return lines.joined(separator: "\n")
    }

    private func sanitizeCode(_ text: String) -> String {
        text.replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "[", with: "_")
            .replacingOccurrences(of: "]", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }
}

private struct MotionRecipeFieldInspector {
    private let rootKeys: Set<String> = [
        "schemaVersion", "recipeName", "description", "target",
        "globalRenderSettings", "globalDefaults", "sections", "sceneOverrides"
    ]
    private let targetKeys: Set<String> = ["matchMode", "sceneRange"]
    private let sceneRangeKeys: Set<String> = ["start", "end"]
    private let globalRenderKeys: Set<String> = ["outputWidth", "outputHeight", "fps", "defaultSceneDuration"]
    private let globalDefaultsKeys: Set<String> = ["durationSeconds", "motionPreset", "transitionIn", "transitionOut"]
    private let sectionKeys: Set<String> = ["name", "sceneRange", "durationSeconds", "motionPreset", "transitionIn", "transitionOut", "notes"]
    private let overrideKeys: Set<String> = ["sequenceIndex", "durationSeconds", "motionPreset", "transitionIn", "transitionOut", "notes", "sceneId", "filenameContains"]

    func ignoredFields(in root: Any) -> [String] {
        var results: [String] = []
        inspect(value: root, path: "", allowedKeys: rootKeys, results: &results)
        return results
    }

    private func inspect(value: Any, path: String, allowedKeys: Set<String>, results: inout [String]) {
        if let dict = value as? [String: Any] {
            for (key, nestedValue) in dict {
                let nextPath = path.isEmpty ? key : "\(path).\(key)"
                if !allowedKeys.contains(key) {
                    results.append(nextPath)
                    continue
                }

                switch key {
                case "target":
                    inspect(value: nestedValue, path: nextPath, allowedKeys: targetKeys, results: &results)
                case "sceneRange":
                    inspect(value: nestedValue, path: nextPath, allowedKeys: sceneRangeKeys, results: &results)
                case "globalRenderSettings":
                    inspect(value: nestedValue, path: nextPath, allowedKeys: globalRenderKeys, results: &results)
                case "globalDefaults":
                    inspect(value: nestedValue, path: nextPath, allowedKeys: globalDefaultsKeys, results: &results)
                case "sections":
                    inspectArray(value: nestedValue, path: nextPath, allowedKeys: sectionKeys, results: &results)
                case "sceneOverrides":
                    inspectArray(value: nestedValue, path: nextPath, allowedKeys: overrideKeys, results: &results)
                default:
                    break
                }
            }
        }
    }

    private func inspectArray(value: Any, path: String, allowedKeys: Set<String>, results: inout [String]) {
        guard let array = value as? [Any] else { return }
        for (index, item) in array.enumerated() {
            inspect(value: item, path: "\(path)[\(index)]", allowedKeys: allowedKeys, results: &results)
        }
    }
}

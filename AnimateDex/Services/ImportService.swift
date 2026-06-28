import Foundation

struct ImportedWorkspaceResult: Sendable {
    let project: AnimateProject
    let scenes: [SceneItem]
    let importReport: ImportReport
    let validationIssues: [ValidationIssue]
}

struct ImportService {
    private let inspectionService = ImageInspectionService()
    private let sequenceService = SequenceDetectionService()
    private let zipService = ZipService()
    private let workspaceService = WorkspaceService()
    private let jsonStore = JSONFileStore()

    func importSource(
        sourceURL: URL,
        into project: AnimateProject,
        renderSettings: RenderSettings
    ) async throws -> ImportedWorkspaceResult {
        let workspaceURL = URL(fileURLWithPath: project.workspacePath)
        let originalsURL = workspaceURL.appendingPathComponent("assets/originals")
        let workingURL = workspaceURL.appendingPathComponent("assets/working")
        try FileManager.default.createDirectory(at: originalsURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: workingURL, withIntermediateDirectories: true)

        let sourceKind: SourceKind = if sourceURL.pathExtension.lowercased() == "zip" { .zip } else { .folder }
        let sourceFiles = try collectSourceFiles(from: sourceURL, sourceKind: sourceKind)

        let supportedExtensions = Set(["png", "jpg", "jpeg", "webp"])
        let supportedFiles = sourceFiles.filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
        let unsupportedFiles = sourceFiles.filter { !supportedExtensions.contains($0.pathExtension.lowercased()) }.map(\.lastPathComponent)

        let copiedURLs = try supportedFiles.enumerated().map { index, source in
            let destination = originalsURL.appendingPathComponent(source.lastPathComponent)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            return (destination, index)
        }

        let inspections = copiedURLs.map { inspectionService.inspect(url: $0.0) }
        let sequenceResult = sequenceService.detect(results: inspections)
        let dominantSize = dominantSize(from: sequenceResult.orderedResults)
        let dominantOrientation = dominantOrientation(from: sequenceResult.orderedResults)
        let planIssues = makeValidationIssues(
            unsupportedFiles: unsupportedFiles,
            inspections: sequenceResult.orderedResults,
            sequenceIssues: sequenceResult.issues,
            dominantSize: dominantSize,
            dominantOrientation: dominantOrientation
        )

        let scenes = buildScenes(
            inspections: sequenceResult.orderedResults,
            workspacePath: workspaceURL.path,
            dominantSize: dominantSize,
            dominantOrientation: dominantOrientation
        )

        let updatedProject = AnimateProject(
            projectName: project.projectName,
            createdAt: project.createdAt,
            updatedAt: .now,
            sourceKind: sourceKind,
            sourcePath: sourceURL.path,
            workspacePath: workspaceURL.path,
            scenePlanPath: "scene_plan.json",
            renderSettings: renderSettings
        )

        let importReport = ImportReport(
            sourceKind: sourceKind,
            sourcePath: sourceURL.path,
            supportedFileCount: inspections.count,
            unsupportedFiles: unsupportedFiles,
            unreadableFiles: inspections.filter { !$0.readable }.map(\.filename),
            dominantSize: dominantSize,
            dominantOrientation: dominantOrientation,
            issues: planIssues,
            importedAt: .now
        )

        try workspaceService.save(project: updatedProject, scenes: scenes, importReport: importReport, to: workspaceURL)

        return ImportedWorkspaceResult(
            project: updatedProject,
            scenes: scenes,
            importReport: importReport,
            validationIssues: planIssues + scenes.flatMap(\.validationIssues)
        )
    }

    private func collectSourceFiles(from sourceURL: URL, sourceKind: SourceKind) throws -> [URL] {
        let enumeratorOptions: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles]
        switch sourceKind {
        case .folder, .unknown:
            guard let enumerator = FileManager.default.enumerator(
                at: sourceURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: enumeratorOptions
            ) else { return [] }
            return enumerator.compactMap { $0 as? URL }.filter { url in
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
                return values?.isRegularFile == true && url.lastPathComponent != ".DS_Store"
            }
        case .zip:
            let tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("AnimateDexImport-\(UUID().uuidString)")
            try zipService.extract(zipURL: sourceURL, into: tempDirectory)
            guard let enumerator = FileManager.default.enumerator(
                at: tempDirectory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: enumeratorOptions
            ) else { return [] }
            return enumerator.compactMap { $0 as? URL }.filter { url in
                let values = try? url.resourceValues(forKeys: [.isRegularFileKey])
                return values?.isRegularFile == true && url.lastPathComponent != ".DS_Store" && !url.pathComponents.contains("__MACOSX")
            }
        }
    }

    private func dominantSize(from inspections: [ImageInspectionResult]) -> String? {
        let grouped = Dictionary(grouping: inspections.filter { $0.width > 0 && $0.height > 0 }, by: { "\($0.width)x\($0.height)" })
        return grouped.max(by: { $0.value.count < $1.value.count })?.key
    }

    private func dominantOrientation(from inspections: [ImageInspectionResult]) -> ImageOrientation {
        let landscape = inspections.filter { $0.width >= $0.height }.count
        let portrait = inspections.filter { $0.height > $0.width }.count
        return portrait > landscape ? .left : .up
    }

    private func makeValidationIssues(
        unsupportedFiles: [String],
        inspections: [ImageInspectionResult],
        sequenceIssues: [ValidationIssue],
        dominantSize: String?,
        dominantOrientation: ImageOrientation
    ) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        if !unsupportedFiles.isEmpty {
            issues.append(
                ValidationIssue(
                    severity: .warning,
                    code: "unsupported_files",
                    message: "Unsupported files were ignored: \(unsupportedFiles.joined(separator: ", "))"
                )
            )
        }

        let unreadable = inspections.filter { !$0.readable }
        if !unreadable.isEmpty {
            issues.append(
                ValidationIssue(
                    severity: .warning,
                    code: "unreadable_images",
                    message: "Unreadable images: \(unreadable.map(\.filename).joined(separator: ", "))"
                )
            )
        }

        if inspections.isEmpty {
            issues.append(
                ValidationIssue(
                    severity: .error,
                    code: "empty_import",
                    message: "No usable images were imported."
                )
            )
        }

        let dominantIsLandscape = dominantOrientation == .up
        for result in inspections {
            if let dominantSize, dominantSize != "\(result.width)x\(result.height)" {
                issues.append(
                    ValidationIssue(
                        severity: .info,
                        code: "irregular_dimensions",
                        message: "\(result.filename) differs from dominant size \(dominantSize)",
                        relatedPath: result.fileURL.path
                    )
                )
            }

            if dominantIsLandscape, result.height > result.width {
                issues.append(
                    ValidationIssue(
                        severity: .warning,
                        code: "portrait_in_landscape_project",
                        message: "\(result.filename) is portrait in a landscape-dominant project.",
                        relatedPath: result.fileURL.path
                    )
                )
            } else if !dominantIsLandscape, result.width > result.height {
                issues.append(
                    ValidationIssue(
                        severity: .warning,
                        code: "landscape_in_portrait_project",
                        message: "\(result.filename) is landscape in a portrait-dominant project.",
                        relatedPath: result.fileURL.path
                    )
                )
            }
        }

        issues.append(contentsOf: sequenceIssues)
        return issues
    }

    private func buildScenes(
        inspections: [ImageInspectionResult],
        workspacePath: String,
        dominantSize: String?,
        dominantOrientation: ImageOrientation
    ) -> [SceneItem] {
        inspections.enumerated().map { index, inspection in
            let irregular = inspection.width == 0 || inspection.height == 0 || (dominantSize != nil && dominantSize != "\(inspection.width)x\(inspection.height)")
            let preset: MotionPreset = if irregular {
                .problemInsert
            } else if inspection.orientation == .up, dominantOrientation == .up {
                .slowPushIn
            } else {
                .lockedOff
            }

            let validationIssues: [ValidationIssue] = if inspection.readable {
                []
            } else {
                [ValidationIssue(severity: .warning, code: "unreadable_image", message: "Image could not be inspected.", relatedPath: inspection.fileURL.path)]
            }

            return SceneItem(
                id: String(format: "scene_%03d", index + 1),
                sequenceIndex: index + 1,
                filename: inspection.filename,
                sourcePath: URL(fileURLWithPath: workspacePath).appendingPathComponent("assets/originals").appendingPathComponent(inspection.filename).path,
                workingPath: URL(fileURLWithPath: workspacePath).appendingPathComponent("assets/working").appendingPathComponent(inspection.filename).path,
                width: inspection.width,
                height: inspection.height,
                fileSizeBytes: inspection.fileSizeBytes,
                durationSeconds: 3.0,
                motionPreset: preset,
                transitionIn: "cut",
                transitionOut: "cut",
                caption: "",
                notes: "",
                validationStatus: validationIssues.isEmpty ? "ok" : "warning",
                validationIssues: validationIssues,
                fileExtension: inspection.fileExtension,
                orientation: inspection.orientation,
                dominantProjectSize: dominantSize,
                differsFromDominantSize: dominantSize != nil && dominantSize != "\(inspection.width)x\(inspection.height)",
                readable: inspection.readable,
                explicitSequenceNumber: inspection.explicitSequenceNumber,
                importOrder: index + 1
            )
        }
    }
}

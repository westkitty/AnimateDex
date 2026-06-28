import Foundation

struct RenderResult: Sendable {
    let success: Bool
    let outputURL: URL
    let manifestURL: URL
    let renderLogURL: URL
    let renderLog: String
}

struct RenderManifest: Codable, Sendable {
    var schemaVersion: Int = 1
    var projectName: String
    var createdAt: Date
    var outputPath: String
    var sceneCount: Int
    var settings: RenderSettings
    var scenes: [RenderManifestScene]
}

struct RenderManifestScene: Codable, Sendable {
    var id: String
    var filename: String
    var motionPreset: MotionPreset
    var durationSeconds: Double
    var sourcePath: String
    var outputSegmentPath: String
}

struct RenderService {
    private let ffmpeg = FFmpegService()
    private let jsonStore = JSONFileStore()

    func render(
        project: AnimateProject,
        scenes: [SceneItem],
        renderSettings: RenderSettings,
        progress: @escaping @Sendable (Double, String) -> Void
    ) async throws -> RenderResult {
        let workspaceURL = URL(fileURLWithPath: project.workspacePath)
        let exportsURL = workspaceURL.appendingPathComponent("exports")
        let logsURL = workspaceURL.appendingPathComponent("logs")
        let tempURL = workspaceURL.appendingPathComponent("temp")
        try FileManager.default.createDirectory(at: exportsURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: logsURL, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)

        let availability = ffmpeg.detect()
        guard availability.available else {
            let logMessage = "ffmpeg not found. Install ffmpeg with Homebrew: brew install ffmpeg\n"
            let logURL = logsURL.appendingPathComponent("render_log.txt")
            try logMessage.data(using: .utf8)?.write(to: logURL, options: .atomic)
            throw NSError(domain: "AnimateDex.Render", code: 1, userInfo: [NSLocalizedDescriptionKey: logMessage])
        }

        var logLines: [String] = ["ffmpeg path: \(availability.path ?? "unknown")"]
        var manifestScenes: [RenderManifestScene] = []
        var segmentURLs: [URL] = []

        for (index, scene) in scenes.enumerated() {
            let segmentURL = tempURL.appendingPathComponent(String(format: "segment_%03d.mp4", index + 1))
            let sourceURL = URL(fileURLWithPath: scene.sourcePath)
            progress(Double(index) / Double(max(scenes.count, 1)), "Rendering \(scene.filename)")
            let result = try ffmpeg.renderSegment(
                inputURL: sourceURL,
                outputURL: segmentURL,
                settings: renderSettings,
                preset: scene.motionPreset,
                duration: scene.durationSeconds,
                irregular: scene.validationStatus != "ok" || scene.motionPreset == .problemInsert
            )
            logLines.append("scene \(scene.id): exit=\(result.exitCode)")
            if !result.standardOutput.isEmpty {
                logLines.append(result.standardOutput)
            }
            if !result.standardError.isEmpty {
                logLines.append(result.standardError)
            }
            segmentURLs.append(segmentURL)
            manifestScenes.append(
                RenderManifestScene(
                    id: scene.id,
                    filename: scene.filename,
                    motionPreset: scene.motionPreset,
                    durationSeconds: scene.durationSeconds,
                    sourcePath: scene.sourcePath,
                    outputSegmentPath: segmentURL.path
                )
            )
        }

        let concatFileURL = tempURL.appendingPathComponent("concat.txt")
        let concatContents = segmentURLs.map { "file '\($0.path.replacingOccurrences(of: "'", with: "\\'"))'" }.joined(separator: "\n")
        try concatContents.data(using: .utf8)?.write(to: concatFileURL, options: .atomic)

        let outputURL = exportsURL.appendingPathComponent(renderSettings.outputFilename)
        let manifestURL = exportsURL.appendingPathComponent("render_manifest.json")
        let renderLogURL = logsURL.appendingPathComponent("render_log.txt")
        let manifest = RenderManifest(
            projectName: project.projectName,
            createdAt: .now,
            outputPath: outputURL.path,
            sceneCount: scenes.count,
            settings: renderSettings,
            scenes: manifestScenes
        )
        try jsonStore.write(manifest, to: manifestURL)

        progress(0.95, "Concatenating segments")
        let concatResult = try ProcessRunner.run(
            launchPath: availability.path ?? "/usr/bin/ffmpeg",
            arguments: [
                "-y",
                "-f", "concat",
                "-safe", "0",
                "-i", concatFileURL.path,
                "-c", "copy",
                outputURL.path
            ]
        )
        logLines.append("concat exit=\(concatResult.exitCode)")
        if !concatResult.standardOutput.isEmpty {
            logLines.append(concatResult.standardOutput)
        }
        if !concatResult.standardError.isEmpty {
            logLines.append(concatResult.standardError)
        }

        let logText = logLines.joined(separator: "\n")
        try logText.data(using: .utf8)?.write(to: renderLogURL, options: .atomic)

        if concatResult.exitCode != 0 {
            throw NSError(
                domain: "AnimateDex.Render",
                code: Int(concatResult.exitCode),
                userInfo: [NSLocalizedDescriptionKey: concatResult.standardError.isEmpty ? "ffmpeg concat failed" : concatResult.standardError]
            )
        }

        progress(1.0, "Render complete")
        return RenderResult(
            success: true,
            outputURL: outputURL,
            manifestURL: manifestURL,
            renderLogURL: renderLogURL,
            renderLog: logText
        )
    }
}

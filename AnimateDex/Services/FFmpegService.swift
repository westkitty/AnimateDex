import Foundation

struct FFmpegAvailability: Sendable {
    let available: Bool
    let path: String?
    let message: String
}

struct FFmpegService {
    func detect() -> FFmpegAvailability {
        do {
            let result = try ProcessRunner.run(launchPath: "/usr/bin/which", arguments: ["ffmpeg"])
            if result.exitCode == 0 {
                let path = result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                return FFmpegAvailability(available: true, path: path.isEmpty ? "ffmpeg" : path, message: "ffmpeg available")
            }
            return FFmpegAvailability(available: false, path: nil, message: "ffmpeg not found")
        } catch {
            return FFmpegAvailability(available: false, path: nil, message: error.localizedDescription)
        }
    }

    func renderSegment(
        inputURL: URL,
        outputURL: URL,
        settings: RenderSettings,
        preset: MotionPreset,
        duration: Double,
        irregular: Bool
    ) throws -> ProcessResult {
        let frameCount = max(1, Int(duration * Double(settings.fps)))
        let fitFilter = "scale=\(settings.outputWidth):\(settings.outputHeight):force_original_aspect_ratio=decrease,pad=\(settings.outputWidth):\(settings.outputHeight):(ow-iw)/2:(oh-ih)/2:black,format=rgba"
        let motionFilter = motionFilter(for: preset, settings: settings, frameCount: frameCount, irregular: irregular)
        let filter = "\(fitFilter),\(motionFilter),format=\(settings.pixelFormat)"

        return try ProcessRunner.run(
            launchPath: detect().path ?? "/usr/bin/ffmpeg",
            arguments: [
                "-y",
                "-loop", "1",
                "-i", inputURL.path,
                "-vf", filter,
                "-t", String(duration),
                "-an",
                "-c:v", settings.videoCodec,
                "-pix_fmt", settings.pixelFormat,
                "-movflags", "+faststart",
                outputURL.path
            ]
        )
    }

    private func motionFilter(for preset: MotionPreset, settings: RenderSettings, frameCount: Int, irregular: Bool) -> String {
        let cappedFrames = max(1, frameCount - 1)
        let safePreset: MotionPreset = irregular ? .lockedOff : (preset == .pulseGlow ? .gentleDrift : preset)

        switch safePreset {
        case .lockedOff:
            return "zoompan=z='1.0':x='(iw-ow)/2':y='(ih-oh)/2':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        case .slowPushIn:
            return "zoompan=z='min(1.0+0.0009*on,1.10)':x='(iw-iw/zoom)/2':y='(ih-ih/zoom)/2':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        case .slowPullOut:
            return "zoompan=z='max(1.10-0.0009*on,1.0)':x='(iw-iw/zoom)/2':y='(ih-ih/zoom)/2':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        case .panLeft:
            return "zoompan=z='1.06':x='(iw-iw/zoom) * (1 - on/\(cappedFrames))':y='(ih-ih/zoom)/2':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        case .panRight:
            return "zoompan=z='1.06':x='(iw-iw/zoom) * (on/\(cappedFrames))':y='(ih-ih/zoom)/2':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        case .panUp:
            return "zoompan=z='1.06':x='(iw-iw/zoom)/2':y='(ih-ih/zoom) * (1 - on/\(cappedFrames))':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        case .panDown:
            return "zoompan=z='1.06':x='(iw-iw/zoom)/2':y='(ih-ih/zoom) * (on/\(cappedFrames))':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        case .gentleDrift:
            return "zoompan=z='1.02+0.003*sin(on/10)':x='(iw-iw/zoom)/2 + 8*sin(on/25)':y='(ih-ih/zoom)/2 + 6*cos(on/28)':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        case .pulseGlow:
            return "zoompan=z='1.02+0.003*sin(on/10)':x='(iw-iw/zoom)/2 + 8*sin(on/25)':y='(ih-ih/zoom)/2 + 6*cos(on/28)':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        case .problemInsert:
            return "zoompan=z='1.0':x='(iw-ow)/2':y='(ih-oh)/2':d=\(frameCount):s=\(settings.outputWidth)x\(settings.outputHeight):fps=\(settings.fps)"
        }
    }
}

import Foundation

struct RenderSettings: Codable, Sendable, Equatable {
    var outputWidth: Int = 1920
    var outputHeight: Int = 1080
    var fps: Int = 30
    var defaultSceneDuration: Double = 3.0
    var transitionDuration: Double = 0.5
    var outputFilename: String = "proof_render.mp4"
    var outputFormat: String = "mp4"
    var videoCodec: String = "libx264"
    var pixelFormat: String = "yuv420p"

    static let `default` = RenderSettings()
}

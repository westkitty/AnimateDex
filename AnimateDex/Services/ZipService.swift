import Foundation

struct ZipService {
    func extract(zipURL: URL, into destinationURL: URL) throws {
        try FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        let result = try ProcessRunner.run(
            launchPath: "/usr/bin/ditto",
            arguments: ["-x", "-k", zipURL.path, destinationURL.path]
        )

        guard result.exitCode == 0 else {
            throw NSError(
                domain: "AnimateDex.ZipService",
                code: Int(result.exitCode),
                userInfo: [NSLocalizedDescriptionKey: result.standardError.isEmpty ? "ZIP extraction failed" : result.standardError]
            )
        }
    }
}

import AppKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ImageInspectionResult: Sendable {
    let fileURL: URL
    let filename: String
    let fileExtension: String
    let fileSizeBytes: Int64
    let width: Int
    let height: Int
    let orientation: ImageOrientation
    let readable: Bool
    let explicitSequenceNumber: Int?
    let sequenceCandidates: [Int]
}

struct ImageInspectionService {
    func inspect(url: URL) -> ImageInspectionResult {
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let sizeBytes = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        let filename = url.lastPathComponent
        let fileExtension = url.pathExtension.lowercased()
        let sequenceCandidates = Self.sequenceCandidates(from: filename)
        let explicitSequenceNumber = sequenceCandidates.last

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return ImageInspectionResult(
                fileURL: url,
                filename: filename,
                fileExtension: fileExtension,
                fileSizeBytes: sizeBytes,
                width: 0,
                height: 0,
                orientation: .unknown,
                readable: false,
                explicitSequenceNumber: explicitSequenceNumber,
                sequenceCandidates: sequenceCandidates
            )
        }

        let width = (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue ?? 0
        let height = (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue ?? 0
        let orientation = orientation(from: properties)

        return ImageInspectionResult(
            fileURL: url,
            filename: filename,
            fileExtension: fileExtension,
            fileSizeBytes: sizeBytes,
            width: width,
            height: height,
            orientation: orientation,
            readable: true,
            explicitSequenceNumber: explicitSequenceNumber,
            sequenceCandidates: sequenceCandidates
        )
    }

    private static func sequenceCandidates(from filename: String) -> [Int] {
        let pattern = #"\d+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(filename.startIndex..., in: filename)
        let matches = regex.matches(in: filename, range: range)
        return matches.compactMap { match in
            guard let swiftRange = Range(match.range, in: filename) else { return nil }
            return Int(filename[swiftRange])
        }
    }

    private func orientation(from properties: [CFString: Any]) -> ImageOrientation {
        guard let rawOrientation = properties[kCGImagePropertyOrientation] as? UInt32 else {
            return .up
        }

        switch rawOrientation {
        case 1: return .up
        case 2: return .upMirrored
        case 3: return .down
        case 4: return .downMirrored
        case 5: return .leftMirrored
        case 6: return .right
        case 7: return .rightMirrored
        case 8: return .left
        default: return .unknown
        }
    }
}

import Foundation

enum NaturalSort {
    static func compare(_ lhs: String, _ rhs: String) -> Bool {
        lhs.compare(rhs, options: [.numeric, .caseInsensitive], locale: .current) == .orderedAscending
    }

    static func sortedURLs(_ urls: [URL]) -> [URL] {
        urls.sorted { compare($0.lastPathComponent, $1.lastPathComponent) }
    }
}

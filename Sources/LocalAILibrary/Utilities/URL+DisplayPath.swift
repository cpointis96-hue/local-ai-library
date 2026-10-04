import Foundation

public extension URL {
    func displayPath(homeURL: URL) -> String {
        let path = standardizedFileURL.path
        let homePath = homeURL.standardizedFileURL.path

        if path == homePath { return "~" }
        let prefix = homePath.hasSuffix("/") ? homePath : homePath + "/"
        guard path.hasPrefix(prefix) else { return path }
        return "~" + path.dropFirst(homePath.count)
    }
}

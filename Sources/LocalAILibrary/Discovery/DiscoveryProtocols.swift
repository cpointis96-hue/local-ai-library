import Foundation

public protocol DiscoveryFileSystem: Sendable {
    func fileExists(at url: URL, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func contentsOfDirectory(at url: URL) throws -> [URL]
}

public struct LocalDiscoveryFileSystem: DiscoveryFileSystem, Sendable {
    public init() {}

    public func fileExists(at url: URL, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        FileManager.default.fileExists(atPath: url.path, isDirectory: isDirectory)
    }

    public func contentsOfDirectory(at url: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
    }
}

public typealias ExecutableLookup = @Sendable (String) -> String?

import Foundation

public enum ConfigurationKind: String, CaseIterable, Hashable, Sendable {
    case codex
    case claude
    case unknown
}

public struct AIConfiguration: Identifiable, Hashable, Sendable {
    public let id: String
    public let kind: ConfigurationKind
    public let path: URL
    public let projectRoot: URL?

    public init(kind: ConfigurationKind, path: URL, projectRoot: URL? = nil) {
        let canonicalPath = path.resolvingSymlinksInPath().standardizedFileURL
        self.id = "configuration:\(canonicalPath.path)"
        self.kind = kind
        self.path = path
        self.projectRoot = projectRoot
    }
}

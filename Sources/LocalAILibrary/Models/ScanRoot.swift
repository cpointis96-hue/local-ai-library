import Foundation

public enum ScanRootKind: String, CaseIterable, Hashable, Sendable {
    case known
    case custom
}

public enum ScanRootSource: String, CaseIterable, Hashable, Sendable {
    case ollama
    case huggingFace
    case mlx
    case lmStudio
    case codex
    case claude
    case custom
}

public struct ScanRoot: Identifiable, Hashable, Sendable {
    public let id: String
    public let url: URL
    public let kind: ScanRootKind
    public let source: ScanRootSource

    public init(url: URL, kind: ScanRootKind, source: ScanRootSource) {
        let canonicalURL = url.resolvingSymlinksInPath().standardizedFileURL
        self.id = "scan-root:\(canonicalURL.path)"
        self.url = url
        self.kind = kind
        self.source = source
    }

    public static func known(url: URL, source: ScanRootSource) -> Self {
        Self(url: url, kind: .known, source: source)
    }

    public static func custom(url: URL) -> Self {
        Self(url: url, kind: .custom, source: .custom)
    }
}

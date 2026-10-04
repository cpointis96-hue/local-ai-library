import Foundation

public enum ModelProvider: String, CaseIterable, Hashable, Sendable {
    case ollama
    case huggingFace
    case mlx
    case lmStudio
    case genericGGUF
    case unknown
}

public enum ModelFormat: String, CaseIterable, Hashable, Sendable {
    case gguf
    case safeTensors
    case binary
    case directory
    case unknown
}

public enum RuntimeType: String, CaseIterable, Hashable, Sendable {
    case ollama
    case mlx
    case llamaCPP
    case lmStudio
}

public struct LocalModel: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let provider: ModelProvider
    public let format: ModelFormat
    public let path: URL
    public let sizeBytes: Int64
    public let repositoryURL: URL?
    public let runtimeHints: Set<RuntimeType>

    public init(
        name: String,
        provider: ModelProvider,
        format: ModelFormat,
        path: URL,
        sizeBytes: Int64 = 0,
        repositoryURL: URL? = nil,
        runtimeHints: Set<RuntimeType> = []
    ) {
        let canonicalPath = path.resolvingSymlinksInPath().standardizedFileURL
        self.id = "model:\(canonicalPath.path)"
        self.name = name
        self.provider = provider
        self.format = format
        self.path = path
        self.sizeBytes = sizeBytes
        self.repositoryURL = repositoryURL
        self.runtimeHints = runtimeHints
    }
}

import Foundation

public struct ModelCandidateMetadata: Sendable, Hashable {
    public var name: String?
    public var provider: ModelProvider?
    public var repositoryURL: URL?
    public var runtimeHints: Set<RuntimeType>

    public init(name: String? = nil, provider: ModelProvider? = nil, repositoryURL: URL? = nil, runtimeHints: Set<RuntimeType> = []) {
        self.name = name
        self.provider = provider
        self.repositoryURL = repositoryURL
        self.runtimeHints = runtimeHints
    }
}

public enum ModelParser {
    public static func parse(candidate: URL, metadata: ModelCandidateMetadata? = nil) -> LocalModel? {
        let url = candidate.standardizedFileURL
        let fileManager = FileManager.default
        var isDirectory = ObjCBool(false)
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return nil }

        let lowerName = url.lastPathComponent.lowercased()
        let format: ModelFormat
        if !isDirectory.boolValue {
            guard let suffix = url.pathExtension.lowercased() as String?,
                  ["gguf", "safetensors", "bin"].contains(suffix) else { return nil }
            format = suffix == "gguf" ? .gguf : suffix == "safetensors" ? .safeTensors : .binary
        } else {
            guard hasMultipleModelSignals(at: url) else { return nil }
            format = .directory
        }

        let inferredProvider = provider(for: url, metadata: metadata)
        var hints = metadata?.runtimeHints ?? []
        if inferredProvider == .ollama { hints.insert(.ollama) }
        if inferredProvider == .lmStudio { hints.insert(.lmStudio) }
        if inferredProvider == .mlx || lowerName.contains("mlx") { hints.insert(.mlx) }

        return LocalModel(
            name: metadata?.name ?? displayName(for: url),
            provider: inferredProvider,
            format: format,
            path: candidate,
            repositoryURL: metadata?.repositoryURL ?? CacheMetadataParser.repositoryURL(for: url),
            runtimeHints: hints
        )
    }

    public static func parseHuggingFaceRepository(at repository: URL) -> (model: LocalModel, snapshot: URL)? {
        let repositoryName = repository.lastPathComponent
        guard repositoryName.hasPrefix("models--") else { return nil }
        let repositoryID = repositoryName.dropFirst("models--".count).replacingOccurrences(of: "--", with: "/")
        let snapshots = repository.appendingPathComponent("snapshots", isDirectory: true)
        guard let snapshot = preferredSnapshot(in: snapshots) else { return nil }
        guard hasWeightFile(in: snapshot), hasModelMetadata(in: snapshot) else { return nil }

        let owner = repositoryID.split(separator: "/").first.map(String.init)?.lowercased()
        let provider: ModelProvider = owner == "mlx-community" ? .mlx : .huggingFace
        let hints: Set<RuntimeType> = provider == .mlx ? [.mlx] : []
        let model = LocalModel(
            name: repositoryID,
            provider: provider,
            format: .directory,
            path: repository,
            repositoryURL: URL(string: "https://huggingface.co/\(repositoryID)"),
            runtimeHints: hints
        )
        return (model, snapshot)
    }

    public static func parseOllamaManifest(at manifest: URL, blobsRoot: URL) -> LocalModel? {
        guard let data = try? Data(contentsOf: manifest), data.count <= 256 * 1024,
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let layers = object["layers"] as? [[String: Any]] else { return nil }

        let modelLayers = layers.filter { ($0["mediaType"] as? String) == "application/vnd.ollama.image.model" }
        guard !modelLayers.isEmpty else { return nil }
        var sizeBytes: Int64 = 0
        for layer in layers {
            guard let digest = layer["digest"] as? String, digest.hasPrefix("sha256:"),
                  FileManager.default.fileExists(atPath: blobsRoot.appendingPathComponent("sha256-" + digest.dropFirst(7)).path) else { return nil }
            sizeBytes += Int64(layer["size"] as? Int ?? 0)
        }
        let components = manifest.standardizedFileURL.pathComponents
        guard let manifestsIndex = components.lastIndex(of: "manifests"), components.count > manifestsIndex + 3 else { return nil }
        let repositoryParts = components[(manifestsIndex + 2)..<(components.count - 1)]
        let tag = components[components.count - 1]
        let repository = repositoryParts.joined(separator: "/")
        let displayRepository = repository.hasPrefix("library/") ? String(repository.dropFirst("library/".count)) : repository
        let name = displayRepository + ":" + tag
        return LocalModel(name: name, provider: .ollama, format: .binary, path: manifest, sizeBytes: sizeBytes, runtimeHints: [.ollama])
    }

    private static func hasMultipleModelSignals(at url: URL) -> Bool {
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: url.path) else { return false }
        let names = Set(entries.map { $0.lowercased() })
        let signals = ["config.json", "tokenizer.json", "tokenizer_config.json", "generation_config.json", "model.safetensors.index.json"]
        let metadataSignals = signals.filter { names.contains($0) }.count
        let weightSignals = entries.contains { name in
            ["gguf", "safetensors", "bin"].contains(URL(fileURLWithPath: name).pathExtension.lowercased())
        }
        return metadataSignals + (weightSignals ? 1 : 0) >= 2
    }

    private static func preferredSnapshot(in snapshots: URL) -> URL? {
        let refsMain = snapshots.deletingLastPathComponent().appendingPathComponent("refs/main")
        if let revision = try? String(contentsOf: refsMain, encoding: .utf8) {
            let referenced = snapshots.appendingPathComponent(revision.trimmingCharacters(in: .whitespacesAndNewlines), isDirectory: true)
            if FileManager.default.fileExists(atPath: referenced.path) { return referenced }
        }
        guard let entries = try? FileManager.default.contentsOfDirectory(at: snapshots, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else { return nil }
        return entries.filter { $0.hasDirectoryPath }.sorted { $0.lastPathComponent < $1.lastPathComponent }.first
    }

    private static func hasModelMetadata(in snapshot: URL) -> Bool {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: snapshot.path).map { $0.lowercased() }) ?? []
        return names.contains("config.json") || names.contains("model.safetensors.index.json")
    }

    private static func hasWeightFile(in snapshot: URL) -> Bool {
        guard let enumerator = FileManager.default.enumerator(at: snapshot, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { return false }
        while let url = enumerator.nextObject() as? URL {
            if ["safetensors", "bin", "gguf"].contains(url.pathExtension.lowercased()) { return true }
        }
        return false
    }

    private static func provider(for url: URL, metadata: ModelCandidateMetadata?) -> ModelProvider {
        if let provider = metadata?.provider { return provider }
        let path = url.path.lowercased()
        if path.contains("/.ollama/") || path.hasSuffix("/.ollama") { return .ollama }
        if path.contains("/.lmstudio/") || path.contains("/lm-studio/") { return .lmStudio }
        if path.contains("huggingface") || path.contains("/models--") { return .huggingFace }
        if path.contains("mlx") { return .mlx }
        if url.pathExtension.lowercased() == "gguf" { return .genericGGUF }
        return .unknown
    }

    private static func displayName(for url: URL) -> String {
        let name = url.hasDirectoryPath ? url.lastPathComponent : url.deletingPathExtension().lastPathComponent
        return name.replacingOccurrences(of: "--", with: "/")
    }
}

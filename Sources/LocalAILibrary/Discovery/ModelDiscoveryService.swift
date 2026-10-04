import Foundation

public struct ModelDiscoveryService: Sendable {
    private let metadataService: FileMetadataService

    public init(metadataService: FileMetadataService = FileMetadataService()) {
        self.metadataService = metadataService
    }

    public func discover(roots: [ScanRoot]) async -> [LocalModel] {
        let candidates = collectCandidates(in: roots)
        var result: [String: LocalModel] = [:]
        for candidate in candidates {
            let model: LocalModel
            let metadataURL: URL?
            switch candidate.kind {
            case .huggingFace(let snapshot):
                guard let parsed = ModelParser.parseHuggingFaceRepository(at: candidate.url) else { continue }
                model = parsed.model
                metadataURL = snapshot
            case .ollama(let blobsRoot):
                guard let parsed = ModelParser.parseOllamaManifest(at: candidate.url, blobsRoot: blobsRoot) else { continue }
                model = parsed
                metadataURL = nil
            case .generic:
                guard let parsed = ModelParser.parse(candidate: candidate.url) else { continue }
                model = parsed
                metadataURL = candidate.url
            }
            let metadata: FileMetadata?
            if let metadataURL { metadata = await metadataService.metadata(for: metadataURL) } else { metadata = nil }
            let enriched = LocalModel(name: model.name, provider: model.provider, format: model.format, path: model.path, sizeBytes: metadata?.sizeBytes ?? model.sizeBytes, repositoryURL: model.repositoryURL, runtimeHints: model.runtimeHints)
            result[enriched.id] = enriched
        }
        return result.values.sorted { ($0.provider.rawValue, $0.name) < ($1.provider.rawValue, $1.name) }
    }

    private enum CandidateKind { case huggingFace(URL); case ollama(URL); case generic }
    private struct Candidate { let url: URL; let kind: CandidateKind }

    private func collectCandidates(in roots: [ScanRoot]) -> [Candidate] {
        var candidates: [Candidate] = []
        for root in roots where exists(root.url) {
            if root.source == .huggingFace || root.url.path.contains("huggingface/hub") {
                let repositories = (try? FileManager.default.contentsOfDirectory(at: root.url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])) ?? []
                for repository in repositories where repository.lastPathComponent.hasPrefix("models--") {
                    if let parsed = ModelParser.parseHuggingFaceRepository(at: repository) { candidates.append(Candidate(url: repository, kind: .huggingFace(parsed.snapshot))) }
                }
                continue
            }
            if root.source == .ollama || root.url.lastPathComponent == "models" && root.url.path.contains(".ollama") {
                let manifests = root.url.appendingPathComponent("manifests", isDirectory: true)
                if let enumerator = FileManager.default.enumerator(at: manifests, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                    while let url = enumerator.nextObject() as? URL {
                        if !url.hasDirectoryPath { candidates.append(Candidate(url: url, kind: .ollama(root.url.appendingPathComponent("blobs", isDirectory: true)))) }
                    }
                }
                continue
            }
            if let enumerator = FileManager.default.enumerator(at: root.url, includingPropertiesForKeys: [.isDirectoryKey], options: []) {
                while let url = enumerator.nextObject() as? URL {
                    let ext = url.pathExtension.lowercased()
                    if ["gguf", "safetensors", "bin"].contains(ext) { candidates.append(Candidate(url: url, kind: .generic)) }
                    else if url.hasDirectoryPath, let model = ModelParser.parse(candidate: url), model.format == .directory { candidates.append(Candidate(url: url, kind: .generic)); enumerator.skipDescendants() }
                }
            }
        }
        return candidates
    }

    private func exists(_ url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}

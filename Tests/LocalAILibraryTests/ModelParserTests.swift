import XCTest
@testable import LocalAILibrary

final class ModelParserTests: XCTestCase {
    func testFormatsBinarySizes() {
        XCTAssertEqual(ByteCountFormatter.string(from: 842 * 1024 * 1024), "842 MB")
        XCTAssertEqual(
            ByteCountFormatter.string(from: Int64(4.7 * 1024 * 1024 * 1024)),
            "4.7 GB"
        )
    }

    func testDisplaysHomeRelativePath() {
        let home = URL(fileURLWithPath: "/Users/test")
        XCTAssertEqual(
            URL(fileURLWithPath: "/Users/test/.ollama/models").displayPath(homeURL: home),
            "~/.ollama/models"
        )
    }

    func testModelIdentityUsesCanonicalPhysicalPath() throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let physical = root.appendingPathComponent("model.gguf")
        try FixtureFileSystem.write("fixture", to: physical)
        let link = root.appendingPathComponent("alias.gguf")
        try FixtureFileSystem.makeSymlink(at: link, pointingTo: physical)

        let first = LocalModel(name: "First", provider: .genericGGUF, format: .gguf, path: physical)
        let second = LocalModel(name: "Second", provider: .genericGGUF, format: .gguf, path: link)
        XCTAssertEqual(first.id, second.id)
        XCTAssertNotEqual(first.name, second.name)
    }

    func testRecognizesGGUFFile() throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let candidate = root.appendingPathComponent("llama-3.gguf")
        try FixtureFileSystem.write("fixture", to: candidate)

        let model = ModelParser.parse(candidate: candidate)
        XCTAssertEqual(model?.format, .gguf)
        XCTAssertEqual(model?.provider, .genericGGUF)
    }

    func testRecognizesSingleSafeTensorsShard() throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let candidate = root.appendingPathComponent("model-00001-of-00001.safetensors")
        try FixtureFileSystem.write("fixture", to: candidate)
        XCTAssertEqual(ModelParser.parse(candidate: candidate)?.format, .safeTensors)
    }

    func testRequiresMultipleDirectorySignals() throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let valid = root.appendingPathComponent("valid", isDirectory: true)
        try FixtureFileSystem.makeDirectory(at: valid)
        try FixtureFileSystem.write("{}", to: valid.appendingPathComponent("config.json"))
        try FixtureFileSystem.write("{}", to: valid.appendingPathComponent("tokenizer.json"))
        XCTAssertEqual(ModelParser.parse(candidate: valid)?.format, .directory)

        let invalid = root.appendingPathComponent("invalid", isDirectory: true)
        try FixtureFileSystem.makeDirectory(at: invalid)
        try FixtureFileSystem.write("{}", to: invalid.appendingPathComponent("config.json"))
        XCTAssertNil(ModelParser.parse(candidate: invalid))
    }

    func testHFCacheUsesRepositoryMetadataAndMLXIsOnlyAHint() throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let cache = root.appendingPathComponent("huggingface/models--acme--tiny", isDirectory: true)
        try FixtureFileSystem.makeDirectory(at: cache)
        try FixtureFileSystem.write("{\"repo_id\":\"acme/tiny\"}", to: cache.appendingPathComponent("model_info.json"))
        let weight = cache.appendingPathComponent("model.safetensors")
        try FixtureFileSystem.write("fixture", to: weight)

        let model = ModelParser.parse(candidate: weight, metadata: ModelCandidateMetadata(runtimeHints: [.mlx]))
        XCTAssertEqual(model?.repositoryURL?.absoluteString, "https://huggingface.co/acme/tiny")
        XCTAssertEqual(model?.runtimeHints, [.mlx])
    }

    func testRuntimeDetectorOnlyChecksExecutablePresence() {
        let found = Set(["ollama", "mlx_lm", "llama-cli"])
        let detector = RuntimeDetector { found.contains($0) ? "/fake/\($0)" : nil }
        XCTAssertEqual(detector.detect(), [.ollama, .mlx, .llamaCPP])
    }

    func testNormalizesHuggingFaceRepositoryAboveSnapshotHash() throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = root.appendingPathComponent("models--mlx-community--Qwen2.5-7B-Instruct-4bit", isDirectory: true)
        let snapshot = repository.appendingPathComponent("snapshots/abc123", isDirectory: true)
        let blobs = repository.appendingPathComponent("blobs", isDirectory: true)
        try FixtureFileSystem.makeDirectory(at: snapshot)
        try FixtureFileSystem.makeDirectory(at: blobs)
        try FixtureFileSystem.write("{}", to: snapshot.appendingPathComponent("config.json"))
        try FixtureFileSystem.write("weights", to: blobs.appendingPathComponent("weight"))
        try FixtureFileSystem.makeSymlink(at: snapshot.appendingPathComponent("model.safetensors"), pointingTo: blobs.appendingPathComponent("weight"))

        let parsed = try XCTUnwrap(ModelParser.parseHuggingFaceRepository(at: repository))
        XCTAssertEqual(parsed.model.name, "mlx-community/Qwen2.5-7B-Instruct-4bit")
        XCTAssertEqual(parsed.model.provider, .mlx)
        XCTAssertEqual(parsed.model.repositoryURL?.absoluteString, "https://huggingface.co/mlx-community/Qwen2.5-7B-Instruct-4bit")
        XCTAssertEqual(parsed.model.path, repository)
        XCTAssertEqual(
            parsed.snapshot.path.replacingOccurrences(of: "/private/var/", with: "/var/"),
            snapshot.path.replacingOccurrences(of: "/private/var/", with: "/var/")
        )
    }

    func testRecognizesUsableOllamaManifestAndLayerBlobs() throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let manifests = root.appendingPathComponent("models/manifests/registry.ollama.ai/library/llama3.1/latest")
        let blobs = root.appendingPathComponent("models/blobs", isDirectory: true)
        try FixtureFileSystem.makeDirectory(at: manifests.deletingLastPathComponent())
        try FixtureFileSystem.makeDirectory(at: blobs)
        let digest = "sha256-abc"
        try FixtureFileSystem.write("layer", to: blobs.appendingPathComponent(digest))
        try FixtureFileSystem.write("{\"layers\":[{\"mediaType\":\"application/vnd.ollama.image.model\",\"digest\":\"sha256:abc\",\"size\":5}]}", to: manifests)

        let model = try XCTUnwrap(ModelParser.parseOllamaManifest(at: manifests, blobsRoot: blobs))
        XCTAssertEqual(model.name, "llama3.1:latest")
        XCTAssertEqual(model.provider, .ollama)
        XCTAssertEqual(model.sizeBytes, 5)
    }
}

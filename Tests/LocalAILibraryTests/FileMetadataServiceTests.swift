import XCTest
@testable import LocalAILibrary

final class FileMetadataServiceTests: XCTestCase {
    func testSumsShardsAndReturnsRepresentativeFiles() async throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try FixtureFileSystem.write(String(repeating: "a", count: 3), to: root.appendingPathComponent("a.safetensors"))
        try FixtureFileSystem.write(String(repeating: "b", count: 5), to: root.appendingPathComponent("b.safetensors"))
        let metadata = await FileMetadataService().metadata(for: root)
        XCTAssertEqual(metadata.sizeBytes, 8)
        XCTAssertEqual(metadata.representativeFiles, ["a.safetensors", "b.safetensors"])
    }

    func testSymlinkIsCountedOnce() async throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let original = root.appendingPathComponent("model.gguf")
        try FixtureFileSystem.write("12345", to: original)
        try FixtureFileSystem.makeSymlink(at: root.appendingPathComponent("alias.gguf"), pointingTo: original)
        let metadata = await FileMetadataService().metadata(for: root)
        XCTAssertEqual(metadata.sizeBytes, 5)
    }
}

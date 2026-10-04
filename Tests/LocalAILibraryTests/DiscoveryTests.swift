import XCTest
@testable import LocalAILibrary

final class DiscoveryTests: XCTestCase {
    func testCustomRootAndPhysicalDuplicateProduceOneModel() async throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = root.appendingPathComponent("model.gguf")
        try FixtureFileSystem.write("small", to: model)
        let alias = root.appendingPathComponent("alias", isDirectory: true)
        try FixtureFileSystem.makeDirectory(at: alias)
        let link = alias.appendingPathComponent("model.gguf")
        try FixtureFileSystem.makeSymlink(at: link, pointingTo: model)
        let models = await ModelDiscoveryService().discover(roots: [.custom(url: root), .custom(url: alias)])
        XCTAssertEqual(models.count, 1)
    }

    func testConfigurationDiscoveryChecksOnlyExplicitRoots() throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try FixtureFileSystem.write("x", to: root.appendingPathComponent(".codex/config.toml"))
        try FixtureFileSystem.write("x", to: root.appendingPathComponent(".claude/settings.json"))
        let configs = ConfigDiscoveryService().discover(roots: [.custom(url: root)])
        XCTAssertEqual(Set(configs.map(\.kind)), [.codex, .claude])
    }

    func testDiscoveryDoesNotModifyFixture() async throws {
        let root = try FixtureFileSystem.makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let model = root.appendingPathComponent("model.gguf")
        try FixtureFileSystem.write("read-only", to: model)
        let beforeData = try Data(contentsOf: model)
        let beforeDate = try XCTUnwrap(FileManager.default.attributesOfItem(atPath: model.path)[.modificationDate] as? Date)
        let beforeNames = try FileManager.default.contentsOfDirectory(atPath: root.path).sorted()

        _ = await ModelDiscoveryService().discover(roots: [.custom(url: root)])

        XCTAssertEqual(try Data(contentsOf: model), beforeData)
        XCTAssertEqual(try FileManager.default.attributesOfItem(atPath: model.path)[.modificationDate] as? Date, beforeDate)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path).sorted(), beforeNames)
    }
}

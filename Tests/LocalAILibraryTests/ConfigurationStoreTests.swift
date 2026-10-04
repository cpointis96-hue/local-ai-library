import XCTest
@testable import LocalAILibrary

final class ConfigurationStoreTests: XCTestCase {
    func testCustomRootsRoundTripWithoutModelIndex() throws {
        let suite = "LocalAILibraryTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = URL(fileURLWithPath: "/tmp/one")
        let second = URL(fileURLWithPath: "/tmp/two")
        ConfigurationStore(defaults: defaults).save(customScanRoots: [first, second, first])
        let store = ConfigurationStore(defaults: defaults)
        XCTAssertEqual(store.customScanRoots.map(\.path), [first.path, second.path])
        XCTAssertNil(defaults.object(forKey: "models"))
    }
}

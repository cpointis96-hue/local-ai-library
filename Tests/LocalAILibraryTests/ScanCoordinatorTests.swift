import XCTest
@testable import LocalAILibrary

final class ScanCoordinatorTests: XCTestCase {
    func testModelFailurePreservesConfigurationResults() async {
        let config = AIConfiguration(kind: .codex, path: URL(fileURLWithPath: "/tmp/config.toml"))
        let coordinator = ScanCoordinator(
            modelDiscoverer: { _ in throw NSError(domain: "fixture", code: 1) },
            configDiscoverer: { _ in [config] },
            runtimeDiscoverer: { [.ollama] }
        )
        let result = await coordinator.scan(roots: [])
        XCTAssertEqual(result.configurations, [config])
        XCTAssertEqual(result.runtimes, [.ollama])
        XCTAssertEqual(result.models, [])
        XCTAssertFalse(result.warnings.isEmpty)
    }

    func testSlowDiscoveryRemainsAsync() async {
        let started = Date()
        let coordinator = ScanCoordinator(
            modelDiscoverer: { _ in
                try? await Task.sleep(nanoseconds: 100_000_000)
                return []
            },
            configDiscoverer: { _ in [] }
        )
        let result = await coordinator.scan(roots: [])
        XCTAssertEqual(result.models, [])
        XCTAssertGreaterThanOrEqual(Date().timeIntervalSince(started), 0.09)
    }
}

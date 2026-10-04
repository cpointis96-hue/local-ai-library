import Foundation

public struct ConfigDiscoveryService: Sendable {
    public init() {}

    public func discover(roots: [ScanRoot]) -> [AIConfiguration] {
        var result: [AIConfiguration] = []
        for root in roots {
            let candidates: [(URL, ConfigurationKind, URL?)]
            switch root.source {
            case .codex:
                candidates = [(root.url.appendingPathComponent("config.toml"), .codex, nil)]
            case .claude:
                candidates = [(root.url.appendingPathComponent("settings.json"), .claude, nil)]
            default:
                candidates = [
                    (root.url.appendingPathComponent(".codex/config.toml"), .codex, root.url),
                    (root.url.appendingPathComponent(".claude/settings.json"), .claude, root.url),
                ]
            }
            for (url, kind, projectRoot) in candidates where FileManager.default.fileExists(atPath: url.path) {
                result.append(AIConfiguration(kind: kind, path: url, projectRoot: projectRoot))
            }
        }
        return Dictionary(uniqueKeysWithValues: result.map { ($0.id, $0) }).values.sorted { $0.path.path < $1.path.path }
    }
}

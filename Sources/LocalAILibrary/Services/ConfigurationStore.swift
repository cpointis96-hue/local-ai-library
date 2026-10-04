import Foundation

public struct ConfigurationStore {
    private let defaults: UserDefaults
    private let rootsKey = "customScanRoots"
    private let selectedKey = "selectedModelID"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var customScanRoots: [URL] {
        (defaults.array(forKey: rootsKey) as? [String] ?? []).map { URL(fileURLWithPath: $0) }
    }

    public var selectedModelID: String? { defaults.string(forKey: selectedKey) }

    public func save(customScanRoots roots: [URL]) {
        var values: [String] = []
        for path in roots.map({ $0.resolvingSymlinksInPath().standardizedFileURL.path }) where !values.contains(path) {
            values.append(path)
        }
        defaults.set(values, forKey: rootsKey)
    }

    public func add(customScanRoot url: URL) -> Bool {
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else { return false }
        save(customScanRoots: customScanRoots + [url])
        return true
    }

    public func remove(customScanRoot url: URL) {
        let target = url.resolvingSymlinksInPath().standardizedFileURL.path
        save(customScanRoots: customScanRoots.filter { $0.resolvingSymlinksInPath().standardizedFileURL.path != target })
    }

    public func save(selectedModelID: String?) {
        if let selectedModelID { defaults.set(selectedModelID, forKey: selectedKey) }
        else { defaults.removeObject(forKey: selectedKey) }
    }
}

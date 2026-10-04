import Foundation

public struct ScanResult: Sendable {
    public let models: [LocalModel]
    public let configurations: [AIConfiguration]
    public let runtimes: Set<RuntimeType>
    public let warnings: [String]

    public init(models: [LocalModel], configurations: [AIConfiguration], runtimes: Set<RuntimeType>, warnings: [String] = []) {
        self.models = models
        self.configurations = configurations
        self.runtimes = runtimes
        self.warnings = warnings
    }
}

public struct ScanCoordinator: Sendable {
    public typealias ModelDiscoverer = @Sendable ([ScanRoot]) async throws -> [LocalModel]
    public typealias ConfigDiscoverer = @Sendable ([ScanRoot]) throws -> [AIConfiguration]
    public typealias RuntimeDiscoverer = @Sendable () -> Set<RuntimeType>

    private let modelDiscoverer: ModelDiscoverer
    private let configDiscoverer: ConfigDiscoverer
    private let runtimeDiscoverer: RuntimeDiscoverer

    public init(
        modelDiscoverer: @escaping ModelDiscoverer = { roots in await ModelDiscoveryService().discover(roots: roots) },
        configDiscoverer: @escaping ConfigDiscoverer = { roots in ConfigDiscoveryService().discover(roots: roots) },
        runtimeDiscoverer: @escaping RuntimeDiscoverer = { RuntimeDetector().detect() }
    ) {
        self.modelDiscoverer = modelDiscoverer
        self.configDiscoverer = configDiscoverer
        self.runtimeDiscoverer = runtimeDiscoverer
    }

    public func scan(roots: [ScanRoot]) async -> ScanResult {
        async let models = discoverModels(roots: roots)
        async let configurations = discoverConfigurations(roots: roots)
        let runtimeSet = runtimeDiscoverer()
        let modelResult = await models
        let configResult = await configurations
        return ScanResult(models: modelResult.value, configurations: configResult.value, runtimes: runtimeSet, warnings: modelResult.warning + configResult.warning)
    }

    private func discoverModels(roots: [ScanRoot]) async -> (value: [LocalModel], warning: [String]) {
        do { return (try await modelDiscoverer(roots), []) }
        catch { return ([], ["Model discovery failed: \(error.localizedDescription)"]) }
    }

    private func discoverConfigurations(roots: [ScanRoot]) async -> (value: [AIConfiguration], warning: [String]) {
        do { return (try configDiscoverer(roots), []) }
        catch { return ([], ["Configuration discovery failed: \(error.localizedDescription)"]) }
    }
}

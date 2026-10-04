import AppKit
import SwiftUI

@MainActor
public final class AppState: ObservableObject {
    public enum Category: String, CaseIterable, Sendable {
        case models
        case configurations
    }

    public enum ScanStatus: Equatable, Sendable {
        case idle
        case scanning
        case finished
    }

    @Published public private(set) var models: [LocalModel] = []
    @Published public private(set) var configurations: [AIConfiguration] = []
    @Published public private(set) var runtimes: Set<RuntimeType> = []
    @Published public private(set) var warnings: [String] = []
    @Published public private(set) var status: ScanStatus = .idle
    @Published public var category: Category = .models
    @Published public var selectedModelID: String?
    @Published public var selectedConfigurationID: String?
    @Published public private(set) var customScanRoots: [URL]

    private let store: ConfigurationStore
    private let coordinator: ScanCoordinator

    public init(store: ConfigurationStore = ConfigurationStore(), coordinator: ScanCoordinator = ScanCoordinator()) {
        self.store = store
        self.coordinator = coordinator
        self.customScanRoots = store.customScanRoots
        self.selectedModelID = store.selectedModelID
    }

    public var isScanning: Bool { status == .scanning }

    public func scan() {
        guard !isScanning else { return }
        status = .scanning
        let roots = allRoots()
        Task { [weak self] in
            let result = await self?.coordinator.scan(roots: roots)
            guard let self, let result else { return }
            self.models = result.models
            self.configurations = result.configurations
            self.runtimes = result.runtimes
            self.warnings = result.warnings
            self.status = .finished
        }
    }

    public func addScanRoot(_ url: URL) {
        guard store.add(customScanRoot: url) else { return }
        customScanRoots = store.customScanRoots
        scan()
    }

    public func removeScanRoot(_ url: URL) {
        store.remove(customScanRoot: url)
        customScanRoots = store.customScanRoots
        scan()
    }

    public func select(model: LocalModel?) {
        selectedModelID = model?.id
        store.save(selectedModelID: selectedModelID)
    }

    public func openFolder(for url: URL) { NSWorkspace.shared.open(url.hasDirectoryPath ? url : url.deletingLastPathComponent()) }
    public func openModelFolder(for model: LocalModel) {
        let modelFolder: URL

        if model.provider == .ollama {
            var folder = model.path.deletingLastPathComponent()
            while folder.path != "/" && folder.lastPathComponent != "manifests" {
                folder.deleteLastPathComponent()
            }
            modelFolder = folder.lastPathComponent == "manifests" ? folder.deletingLastPathComponent() : folder
        } else {
            modelFolder = model.path.hasDirectoryPath ? model.path : model.path.deletingLastPathComponent()
        }

        NSWorkspace.shared.open(modelFolder)
    }
    public func copyPath(for url: URL) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(url.path, forType: .string) }
    public func copyText(_ value: String) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(value, forType: .string) }
    public func openRepository(for url: URL?) { guard let url, url.scheme == "https", url.host == "huggingface.co" else { return }; NSWorkspace.shared.open(url) }

    private func allRoots() -> [ScanRoot] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var roots: [ScanRoot] = [
            .known(url: home.appendingPathComponent(".ollama/models", isDirectory: true), source: .ollama),
            .known(url: home.appendingPathComponent(".cache/huggingface/hub", isDirectory: true), source: .huggingFace),
            .known(url: home.appendingPathComponent(".lmstudio/models", isDirectory: true), source: .lmStudio),
            .known(url: home.appendingPathComponent(".codex", isDirectory: true), source: .codex),
            .known(url: home.appendingPathComponent(".claude", isDirectory: true), source: .claude),
        ]
        roots += customScanRoots.map(ScanRoot.custom)
        return roots
    }
}

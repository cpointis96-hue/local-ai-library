import SwiftUI

struct ConfigurationDetailView: View {
    let configuration: AIConfiguration?
    @EnvironmentObject private var state: AppState

    var body: some View {
        Group {
            if let configuration {
                VStack(alignment: .leading, spacing: 0) {
                    Text(configuration.path.path)
                        .font(AppDesign.Typography.metadata)
                        .foregroundStyle(AppDesign.Colors.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(configuration.path.path)
                        .padding(.horizontal, AppDesign.Spacing.xxl)
                        .padding(.vertical, AppDesign.Spacing.lg)
                    ScrollView {
                        Text(readContent(configuration.path))
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppDesign.Spacing.xxl)
                            .padding(.vertical, AppDesign.Spacing.lg)
                    }
                    HStack(spacing: AppDesign.Spacing.md) {
                        Button("Open in Default Editor") { NSWorkspace.shared.open(configuration.path) }
                        Button("Open Folder") { state.openFolder(for: configuration.path) }
                        Button("Copy Path") { state.copyPath(for: configuration.path) }
                    }
                    .controlSize(.regular)
                    .padding(AppDesign.Spacing.xxl)
                }.navigationTitle(configuration.path.lastPathComponent)
            } else { EmptyStateView(title: "Select a configuration", message: "Choose a configuration file to view it without editing.") }
        }
    }

    private func readContent(_ url: URL) -> String {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return "Unable to read this file." }
        defer { try? handle.close() }
        let data = (try? handle.read(upToCount: 512 * 1024)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "Unable to display this file as UTF-8 text."
    }
}

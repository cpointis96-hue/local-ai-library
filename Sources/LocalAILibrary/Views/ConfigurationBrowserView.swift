import SwiftUI

struct ConfigurationBrowserView: View {
    let configurations: [AIConfiguration]
    let kind: ConfigurationKind?
    @Binding var selectedID: String?

    private var filtered: [AIConfiguration] { configurations.filter { kind == nil || $0.kind == kind } }
    var body: some View {
        Group {
            if filtered.isEmpty { EmptyStateView(title: "No configuration files", message: "No known configuration was found in the supplied roots.") }
            else {
                List(selection: $selectedID) {
                    Section("GLOBAL") {
                        ForEach(filtered.filter { $0.projectRoot == nil }) { config in ConfigRow(config: config).tag(Optional(config.id)) }
                    }
                    Section("PROJECTS") {
                        ForEach(filtered.filter { $0.projectRoot != nil }) { config in ConfigRow(config: config).tag(Optional(config.id)) }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppDesign.Colors.windowBackground)
        .navigationTitle("Configurations")
        .navigationSplitViewColumnWidth(
            min: AppDesign.Width.browserMin,
            ideal: AppDesign.Width.browserIdeal,
            max: AppDesign.Width.browserMax
        )
    }
}

private struct ConfigRow: View {
    let config: AIConfiguration
    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
            Text(config.path.lastPathComponent)
                .font(AppDesign.Typography.row)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.tail)
            Text(config.path.path)
                .font(AppDesign.Typography.metadata)
                .foregroundStyle(AppDesign.Colors.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(config.path.path)
        }
        .padding(.vertical, AppDesign.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

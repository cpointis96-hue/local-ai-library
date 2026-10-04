import SwiftUI

struct ModelBrowserView: View {
    @EnvironmentObject private var state: AppState
    let models: [LocalModel]
    let provider: ModelProvider?
    @Binding var selectedID: String?

    private var filtered: [LocalModel] {
        guard let provider else { return models }
        if provider == .huggingFace { return models.filter { $0.provider == .huggingFace || $0.provider == .mlx } }
        return models.filter { $0.provider == provider }
    }
    private var groups: [(String, [LocalModel])] {
        Dictionary(grouping: filtered, by: { $0.provider == .mlx ? ModelProvider.huggingFace.rawValue : $0.provider.rawValue }).map { ($0.key, $0.value.sorted { $0.name < $1.name }) }.sorted { $0.0 < $1.0 }
    }

    var body: some View {
        Group {
            if filtered.isEmpty { EmptyStateView(title: "No models found", message: "This category has no recognized local models.") }
            else {
                List(selection: $selectedID) {
                    ForEach(groups, id: \.0) { source, entries in
                        Section(sourceLabel(source)) {
                            ForEach(entries) { model in
                                ModelRow(model: model)
                                    .tag(Optional(model.id))
                            }
                        }
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppDesign.Colors.windowBackground)
        .navigationTitle("Models")
        .navigationSplitViewColumnWidth(
            min: AppDesign.Width.browserMin,
            ideal: AppDesign.Width.browserIdeal,
            max: AppDesign.Width.browserMax
        )
    }

    private func sourceLabel(_ source: String) -> String { source == "huggingFace" ? "Hugging Face" : source.capitalized }
}

private struct ModelRow: View {
    let model: LocalModel

    var body: some View {
        HStack {
            Text(model.name)
                .font(AppDesign.Typography.row)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
                .help(model.name)
            Spacer()
            Text(ByteCountFormatter.string(from: model.sizeBytes))
                .font(AppDesign.Typography.row)
                .fontWeight(.medium)
                .foregroundStyle(AppDesign.Colors.secondaryText)
                .lineLimit(1)
        }
        .padding(.vertical, AppDesign.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

import SwiftUI

struct ModelDetailView: View {
    let model: LocalModel?
    @EnvironmentObject private var state: AppState

    var body: some View {
        Group {
            if let model {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        InspectorRow(label: "Name", value: model.name, action: nil)
                        InspectorRow(label: "Format", value: model.format.rawValue, action: nil)
                        InspectorRow(label: "Size", value: ByteCountFormatter.string(from: model.sizeBytes), action: nil)
                        InspectorRow(label: "Local status", value: "Ready locally", action: nil)
                        InspectorRow(label: "Repository", value: model.repositoryURL?.absoluteString ?? "Not available") {
                            if let url = model.repositoryURL { state.copyText(url.absoluteString) }
                        }
                        InspectorRow(label: "Runtime", value: model.runtimeHints.map(\.rawValue).sorted().joined(separator: ", ").isEmpty ? "Not detected" : model.runtimeHints.map(\.rawValue).sorted().joined(separator: ", "), action: nil)
                    }
                    .padding(.horizontal, AppDesign.Spacing.xxl)
                    .frame(maxWidth: AppDesign.Width.detailMax, alignment: .leading)
                }
                .navigationTitle(model.name)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            state.openModelFolder(for: model)
                        } label: {
                            Image(systemName: "folder")
                        }
                        .help("Open model folder")
                        .accessibilityLabel("Open model folder")
                    }
                }
            } else { EmptyStateView(title: "Select a model", message: "Choose a model to inspect its read-only details.") }
        }
    }
}

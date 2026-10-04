import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    @State private var selection: SidebarSelection = .model(nil)

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .environmentObject(state)
                .navigationSplitViewColumnWidth(
                    min: AppDesign.Width.sidebarMin,
                    ideal: AppDesign.Width.sidebarIdeal,
                    max: AppDesign.Width.sidebarMax
                )
        } content: {
            switch selection {
            case .model(let provider): ModelBrowserView(models: state.models, provider: provider, selectedID: $state.selectedModelID)
            case .configuration(let kind): ConfigurationBrowserView(configurations: state.configurations, kind: kind, selectedID: $state.selectedConfigurationID)
            }
        } detail: {
            switch selection {
            case .model: ModelDetailView(model: state.models.first { $0.id == state.selectedModelID }).environmentObject(state)
            case .configuration: ConfigurationDetailView(configuration: state.configurations.first { $0.id == state.selectedConfigurationID }).environmentObject(state)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    state.scan()
                } label: {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
                .disabled(state.isScanning)
                .help("Scan local model and configuration roots")
            }
            if state.isScanning { ToolbarItem { ProgressView().controlSize(.small) } }
        }
        .onAppear { if state.status == .idle { state.scan() } }
        .background(AppDesign.Colors.windowBackground.ignoresSafeArea())
    }
}

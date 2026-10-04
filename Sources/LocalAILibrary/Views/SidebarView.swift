import AppKit
import SwiftUI

enum SidebarSelection: Hashable {
    case model(ModelProvider?)
    case configuration(ConfigurationKind?)
}

struct SidebarView: View {
    @Binding var selection: SidebarSelection

    private let modelProviders: [(String, ModelProvider?)] = [
        ("Ollama", .ollama), ("Hugging Face", .huggingFace)
    ]

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(modelProviders, id: \.0) { title, provider in
                    NavigationLink(value: SidebarSelection.model(provider)) {
                        SidebarRow(
                            title: title,
                            icon: provider == .ollama ? nil : "shippingbox",
                            customIcon: AnyView(BrandLogoView(provider: provider ?? .unknown))
                        )
                    }
                }
            } header: {
                SectionLabel(title: "Models")
                    .padding(.top, AppDesign.Spacing.sm)
            }
            Section {
                configurationLink("Codex", kind: .codex)
                configurationLink("Claude", kind: .claude)
                configurationLink("Ollama", kind: nil)
                configurationLink("Other", kind: .unknown)
            } header: {
                SectionLabel(title: "Configuration")
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(AppDesign.Colors.sidebarBackground)
        .navigationTitle("Library")
    }

    @ViewBuilder
    private func configurationLink(_ title: String, kind: ConfigurationKind?) -> some View {
        NavigationLink(value: SidebarSelection.configuration(kind)) {
            SidebarRow(title: title, icon: "doc.text")
        }
    }
}

private struct SidebarRow: View {
    let title: String
    let icon: String?
    let customIcon: AnyView?

    init(title: String, icon: String? = nil, customIcon: AnyView? = nil) {
        self.title = title
        self.icon = icon
        self.customIcon = customIcon
    }

    var body: some View {
        HStack(spacing: AppDesign.Spacing.md) {
            if let customIcon {
                customIcon
                    .frame(width: 18, height: 18)
            } else if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18)
            }
            Text(title)
                .font(AppDesign.Typography.row)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 0)
        }
        .frame(minHeight: AppDesign.Control.prominentHeight, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityLabel(title)
        .help(title)
    }
}

private struct BrandLogoView: View {
    let provider: ModelProvider

    var body: some View {
        if let image = logoImage {
            Image(nsImage: image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.primary)
        } else {
            Image(systemName: "cube")
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.primary)
                .font(.system(size: 15, weight: .medium))
        }
    }

    private var logoImage: NSImage? {
        let resource = provider == .ollama ? "ollama-logo" : "huggingface-logo"
        let url = Bundle.main.url(forResource: resource, withExtension: "svg") ?? Bundle.module.url(forResource: resource, withExtension: "svg")
        guard let url,
              let image = NSImage(contentsOf: url) else { return nil }
        image.isTemplate = true
        return image
    }

}

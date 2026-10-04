import SwiftUI

@main
struct LocalAILibraryApp: App {
    @StateObject private var state = AppState()
    @AppStorage("appearancePreference") private var appearancePreference = AppearancePreference.system.rawValue

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .preferredColorScheme(selectedColorScheme)
        }
        .commands { AppearanceCommands(preference: $appearancePreference) }
        // Keep the first launch compact and close to the reference window proportion.
        // Users can still resize the window freely after launch.
        .defaultSize(width: 1600, height: 760)
        .windowToolbarStyle(.unifiedCompact)
    }

    private var selectedColorScheme: ColorScheme? {
        AppearancePreference(rawValue: appearancePreference)?.colorScheme
    }
}

enum AppearancePreference: String, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: "System Default"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private struct AppearanceCommands: Commands {
    @Binding var preference: String

    var body: some Commands {
        CommandMenu("Appearance") {
            appearanceButton(.system)
            appearanceButton(.light)
                .keyboardShortcut("1", modifiers: [.command, .option])
            appearanceButton(.dark)
                .keyboardShortcut("2", modifiers: [.command, .option])
        }
    }

    private func appearanceButton(_ appearance: AppearancePreference) -> some View {
        Button {
            preference = appearance.rawValue
        } label: {
            HStack {
                Text(appearance.title)
                Spacer()
                if preference == appearance.rawValue {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

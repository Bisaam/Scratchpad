import SwiftUI

struct GeneralSettingsTab: View {
    @Bindable var settingsStore: SettingsStore
    let launchAtLoginService: LaunchAtLoginService

    @State private var launchAtLoginEnabled: Bool

    init(settingsStore: SettingsStore, launchAtLoginService: LaunchAtLoginService) {
        self.settingsStore = settingsStore
        self.launchAtLoginService = launchAtLoginService
        _launchAtLoginEnabled = State(initialValue: launchAtLoginService.isEnabled)
    }

    var body: some View {
        Form {
            LabeledContent("Global Shortcut") {
                ShortcutRecorderView(combo: $settingsStore.settings.globalShortcut)
                    .frame(width: 140, height: 24)
            }

            Picker("Show Overlay On", selection: $settingsStore.settings.displayMode) {
                Text("All Displays").tag(AppSettings.DisplayMode.allDisplays)
                Text("Current Display Only").tag(AppSettings.DisplayMode.currentDisplayOnly)
            }

            Toggle("Launch at Login", isOn: $launchAtLoginEnabled)
                .onChange(of: launchAtLoginEnabled) { _, newValue in
                    do {
                        try launchAtLoginService.setEnabled(newValue)
                    } catch {
                        launchAtLoginEnabled = launchAtLoginService.isEnabled
                    }
                }
        }
        .padding()
    }
}

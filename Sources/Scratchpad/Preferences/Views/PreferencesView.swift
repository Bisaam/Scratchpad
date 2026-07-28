import SwiftUI

struct PreferencesView: View {
    let settingsStore: SettingsStore
    let launchAtLoginService: LaunchAtLoginService

    var body: some View {
        TabView {
            GeneralSettingsTab(settingsStore: settingsStore, launchAtLoginService: launchAtLoginService)
                .tabItem { Label("General", systemImage: "gearshape") }

            AppearanceSettingsTab(settingsStore: settingsStore)
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 420, height: 260)
    }
}

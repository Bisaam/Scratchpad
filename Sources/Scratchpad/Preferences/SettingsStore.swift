import Observation

/// The single observable source of truth for user preferences. SwiftUI
/// views read and write `settings` directly; every change is persisted
/// automatically.
@Observable
final class SettingsStore {
    var settings: AppSettings {
        didSet {
            guard settings != oldValue else { return }
            persistence.saveSettings(settings)
        }
    }

    private let persistence: SettingsPersisting

    init(persistence: SettingsPersisting = UserDefaultsSettingsPersistence()) {
        self.persistence = persistence
        self.settings = persistence.loadSettings() ?? .defaultValue
    }
}

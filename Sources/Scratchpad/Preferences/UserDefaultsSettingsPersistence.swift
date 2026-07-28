import Foundation

/// Stores `AppSettings` as a single JSON-encoded blob in `UserDefaults`,
/// rather than one key per field, so adding a preference never requires
/// touching a list of key strings scattered across the app.
final class UserDefaultsSettingsPersistence: SettingsPersisting {
    private static let key = "com.scratchpad.appSettings"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadSettings() -> AppSettings? {
        guard let data = userDefaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: Self.key)
    }
}

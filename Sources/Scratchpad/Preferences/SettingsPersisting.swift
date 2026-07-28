/// Reads and writes the raw `AppSettings` blob. Kept separate from
/// `SettingsStore` so tests can substitute an in-memory implementation
/// without touching real `UserDefaults`.
protocol SettingsPersisting {
    func loadSettings() -> AppSettings?
    func saveSettings(_ settings: AppSettings)
}

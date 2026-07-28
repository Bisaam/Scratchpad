import Testing
@testable import Scratchpad

private final class InMemorySettingsPersistence: SettingsPersisting {
    private(set) var savedSettings: AppSettings?
    var settingsToLoad: AppSettings?

    func loadSettings() -> AppSettings? { settingsToLoad }
    func saveSettings(_ settings: AppSettings) { savedSettings = settings }
}

struct SettingsStoreTests {

    @Test func fallsBackToDefaultValueWhenNothingIsPersisted() {
        let persistence = InMemorySettingsPersistence()
        let store = SettingsStore(persistence: persistence)

        #expect(store.settings == .defaultValue)
    }

    @Test func loadsPreviouslyPersistedSettings() {
        let persistence = InMemorySettingsPersistence()
        var custom = AppSettings.defaultValue
        custom.backgroundDimOpacity = 0.5
        persistence.settingsToLoad = custom

        let store = SettingsStore(persistence: persistence)

        #expect(store.settings == custom)
    }

    @Test func changingSettingsPersistsTheNewValue() {
        let persistence = InMemorySettingsPersistence()
        let store = SettingsStore(persistence: persistence)

        store.settings.backgroundDimOpacity = 0.15

        #expect(persistence.savedSettings?.backgroundDimOpacity == 0.15)
    }

    @Test func settingTheSameValueDoesNotTriggerAnUnnecessarySave() {
        let persistence = InMemorySettingsPersistence()
        persistence.settingsToLoad = .defaultValue
        let store = SettingsStore(persistence: persistence)

        store.settings = .defaultValue

        #expect(persistence.savedSettings == nil)
    }
}

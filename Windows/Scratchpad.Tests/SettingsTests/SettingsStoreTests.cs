using Scratchpad.Preferences;
using Xunit;

namespace Scratchpad.Tests.SettingsTests;

internal sealed class InMemorySettingsPersistence : ISettingsPersistence
{
    public AppSettings? SavedSettings { get; private set; }
    public AppSettings? SettingsToLoad { get; set; }

    public AppSettings? LoadSettings() => SettingsToLoad;
    public void SaveSettings(AppSettings settings) => SavedSettings = settings;
}

public class SettingsStoreTests
{
    [Fact]
    public void FallsBackToDefaultValueWhenNothingIsPersisted()
    {
        var persistence = new InMemorySettingsPersistence();
        var store = new SettingsStore(persistence);

        Assert.Equal(AppSettings.Default, store.Settings);
    }

    [Fact]
    public void LoadsPreviouslyPersistedSettings()
    {
        var persistence = new InMemorySettingsPersistence();
        var custom = AppSettings.Default with { BackgroundDimOpacity = 0.5 };
        persistence.SettingsToLoad = custom;

        var store = new SettingsStore(persistence);

        Assert.Equal(custom, store.Settings);
    }

    [Fact]
    public void ChangingSettingsPersistsTheNewValue()
    {
        var persistence = new InMemorySettingsPersistence();
        var store = new SettingsStore(persistence);

        store.Settings = store.Settings with { BackgroundDimOpacity = 0.15 };

        Assert.Equal(0.15, persistence.SavedSettings?.BackgroundDimOpacity);
    }

    [Fact]
    public void SettingTheSameValueDoesNotTriggerAnUnnecessarySave()
    {
        var persistence = new InMemorySettingsPersistence { SettingsToLoad = AppSettings.Default };
        var store = new SettingsStore(persistence);

        store.Settings = AppSettings.Default;

        Assert.Null(persistence.SavedSettings);
    }
}

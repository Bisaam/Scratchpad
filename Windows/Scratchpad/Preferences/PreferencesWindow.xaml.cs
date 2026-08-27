using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using Scratchpad.Drawing;
using Scratchpad.TrayIcon;

namespace Scratchpad.Preferences;

/// Hosts every user-facing preference the macOS app's SwiftUI
/// `PreferencesView` exposes (`GeneralSettingsTab`/`AppearanceSettingsTab`),
/// wired imperatively rather than through WPF data binding: `AppSettings` is
/// an immutable record, so each control change reads `_settingsStore.Settings`,
/// produces an updated copy via a `with` expression, and writes the whole
/// record back -- the same "replace the whole value" pattern the macOS
/// `SettingsStore` relies on for its own change detection.
public partial class PreferencesWindow : Window
{
    private readonly SettingsStore _settingsStore;
    private readonly ILaunchAtLoginService _launchAtLoginService;
    private readonly KeyRecorderControl _shortcutRecorder;
    private bool _isLoadingValues;

    public PreferencesWindow(SettingsStore settingsStore, ILaunchAtLoginService launchAtLoginService)
    {
        // Fields must be assigned, and _isLoadingValues raised, before
        // InitializeComponent(): loading the XAML sets each Slider's
        // initial Value/Minimum, which raises ValueChanged synchronously
        // during BAML parsing -- before this constructor would otherwise
        // reach its own body. Without this ordering, OnAnimationDurationChanged
        // et al. run with _settingsStore still null and crash the app on
        // startup with a NullReferenceException.
        _isLoadingValues = true;
        _settingsStore = settingsStore;
        _launchAtLoginService = launchAtLoginService;
        InitializeComponent();

        _shortcutRecorder = new KeyRecorderControl(_settingsStore.Settings.GlobalShortcut);
        _shortcutRecorder.ComboChanged += combo =>
            _settingsStore.Settings = _settingsStore.Settings with { GlobalShortcut = combo };
        ShortcutRecorderHost.Content = _shortcutRecorder;

        LoadValuesFromSettings();
    }

    private void LoadValuesFromSettings()
    {
        _isLoadingValues = true;
        var settings = _settingsStore.Settings;

        DisplayModeComboBox.SelectedIndex = settings.DisplayMode == AppSettings.OverlayDisplayMode.AllDisplays ? 0 : 1;
        LaunchAtLoginCheckBox.IsChecked = _launchAtLoginService.IsEnabled;

        DimOpacitySlider.Value = settings.BackgroundDimOpacity;
        AnimationDurationSlider.Value = settings.AnimationDuration;
        StrokeWidthSlider.Value = settings.StrokeWidth;
        UpdatePencilColorSwatch(settings.StrokeColor);
        UpdateAnimationDurationLabel(settings.AnimationDuration);
        UpdateStrokeWidthLabel(settings.StrokeWidth);

        _isLoadingValues = false;
    }

    private void OnDisplayModeChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_isLoadingValues) return;
        var mode = DisplayModeComboBox.SelectedIndex == 0
            ? AppSettings.OverlayDisplayMode.AllDisplays
            : AppSettings.OverlayDisplayMode.CurrentDisplayOnly;
        _settingsStore.Settings = _settingsStore.Settings with { DisplayMode = mode };
    }

    private void OnLaunchAtLoginChanged(object sender, RoutedEventArgs e)
    {
        if (_isLoadingValues) return;
        var enabled = LaunchAtLoginCheckBox.IsChecked == true;
        try
        {
            _launchAtLoginService.SetEnabled(enabled);
        }
        catch (Exception)
        {
            LaunchAtLoginCheckBox.IsChecked = _launchAtLoginService.IsEnabled;
        }
    }

    private void OnDimOpacityChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_isLoadingValues) return;
        _settingsStore.Settings = _settingsStore.Settings with { BackgroundDimOpacity = e.NewValue };
    }

    private void OnDimPresetClick(object sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string tagValue }) return;
        var preset = double.Parse(tagValue, System.Globalization.CultureInfo.InvariantCulture);
        DimOpacitySlider.Value = preset;
    }

    private void OnAnimationDurationChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        UpdateAnimationDurationLabel(e.NewValue);
        if (_isLoadingValues) return;
        _settingsStore.Settings = _settingsStore.Settings with { AnimationDuration = e.NewValue };
    }

    private void OnStrokeWidthChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        UpdateStrokeWidthLabel(e.NewValue);
        if (_isLoadingValues) return;
        _settingsStore.Settings = _settingsStore.Settings with { StrokeWidth = e.NewValue };
    }

    private void OnPencilColorClick(object sender, RoutedEventArgs e)
    {
        using var dialog = new System.Windows.Forms.ColorDialog
        {
            Color = _settingsStore.Settings.StrokeColor.ToDrawingColor(),
            FullOpen = true,
        };
        if (dialog.ShowDialog() != System.Windows.Forms.DialogResult.OK) return;

        var newColor = dialog.Color.ToStrokeColor();
        _settingsStore.Settings = _settingsStore.Settings with { StrokeColor = newColor };
        UpdatePencilColorSwatch(newColor);
    }

    private void UpdatePencilColorSwatch(StrokeColor color)
    {
        PencilColorButton.Background = new SolidColorBrush(color.ToMediaColor());
    }

    private void UpdateAnimationDurationLabel(double duration) =>
        AnimationDurationLabel.Text = $"Animation Duration: {duration:0.00}s";

    private void UpdateStrokeWidthLabel(double width) =>
        StrokeWidthLabel.Text = $"Pencil Thickness: {width:0.0}pt";
}

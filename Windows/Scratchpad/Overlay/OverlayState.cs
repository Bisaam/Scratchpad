using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace Scratchpad.Overlay;

/// Whether the overlay is currently shown, and nothing else. Deliberately
/// minimal: no drawing data lives here, and no fading-in-progress
/// bookkeeping either (that is a private implementation detail of
/// `OverlayWindowController`). Keeping this to a single fact is what makes
/// overlay visibility and drawing content genuinely independent, per
/// CLAUDE.md's requirement that they never be coupled.
public sealed class OverlayState : INotifyPropertyChanged
{
    private bool _isVisible;

    public bool IsVisible
    {
        get => _isVisible;
        private set
        {
            if (_isVisible == value) return;
            _isVisible = value;
            OnPropertyChanged();
        }
    }

    public void SetVisible(bool visible) => IsVisible = visible;

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? propertyName = null) =>
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
}

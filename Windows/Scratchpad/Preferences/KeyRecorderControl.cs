using System.Globalization;
using System.Windows;
using System.Windows.Input;
using System.Windows.Interop;
using System.Windows.Media;
using Scratchpad.Hotkeys;

namespace Scratchpad.Preferences;

/// A small clickable control that captures the next key combination typed
/// while it has focus and reports it as a `KeyCombo`. WPF has no stock
/// control for this, so it is built directly on `FrameworkElement` rather
/// than wrapping something that doesn't quite fit -- mirrors the macOS
/// app's `KeyRecorderView`.
public sealed class KeyRecorderControl : FrameworkElement
{
    public KeyCombo Combo { get; private set; }

    public event Action<KeyCombo>? ComboChanged;

    private bool _isRecording;

    public KeyRecorderControl(KeyCombo initialCombo)
    {
        Combo = initialCombo;
        Focusable = true;
        Cursor = Cursors.Hand;
        Height = 28;
        Width = 140;
    }

    protected override void OnMouseDown(MouseButtonEventArgs e)
    {
        Focus();
        _isRecording = true;
        InvalidateVisual();
        e.Handled = true;
    }

    protected override void OnPreviewKeyDown(KeyEventArgs e)
    {
        if (!_isRecording)
        {
            base.OnPreviewKeyDown(e);
            return;
        }

        var key = e.Key == Key.System ? e.SystemKey : e.Key;
        if (IsModifierOnly(key))
        {
            e.Handled = true;
            return;
        }

        var newCombo = new KeyCombo((uint)KeyInterop.VirtualKeyFromKey(key), Keyboard.Modifiers);
        Combo = newCombo;
        _isRecording = false;
        InvalidateVisual();
        ComboChanged?.Invoke(newCombo);
        e.Handled = true;
    }

    protected override void OnLostFocus(RoutedEventArgs e)
    {
        _isRecording = false;
        InvalidateVisual();
        base.OnLostFocus(e);
    }

    private static bool IsModifierOnly(Key key) =>
        key is Key.LeftCtrl or Key.RightCtrl or Key.LeftAlt or Key.RightAlt
            or Key.LeftShift or Key.RightShift or Key.LWin or Key.RWin or Key.System;

    protected override void OnRender(DrawingContext drawingContext)
    {
        var bounds = new Rect(0, 0, ActualWidth, ActualHeight);
        var geometry = new RectangleGeometry(bounds, 6, 6);
        drawingContext.DrawGeometry(SystemColors.ControlLightBrush, new Pen(SystemColors.ActiveBorderBrush, 1), geometry);

        var text = _isRecording ? "Press a key…" : Combo.DisplayString;
        var formattedText = new FormattedText(
            text,
            CultureInfo.CurrentCulture,
            FlowDirection.LeftToRight,
            new Typeface("Segoe UI"),
            12,
            _isRecording ? SystemColors.GrayTextBrush : SystemColors.ControlTextBrush,
            VisualTreeHelper.GetDpi(this).PixelsPerDip);
        var origin = new Point((ActualWidth - formattedText.Width) / 2, (ActualHeight - formattedText.Height) / 2);
        drawingContext.DrawText(formattedText, origin);
    }
}

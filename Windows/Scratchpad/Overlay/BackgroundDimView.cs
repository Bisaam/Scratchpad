using System.Windows.Controls;
using System.Windows.Media;

namespace Scratchpad.Overlay;

/// A solid black backdrop behind the drawing canvas, at a configurable
/// opacity (SPEC.md's background dim). Its own opacity is fixed once
/// visible; the overlay's fade in/out animates the whole window's
/// `Opacity` instead, so this view has no animation logic of its own.
/// Mirrors the macOS app's `DimBackgroundView`.
public sealed class BackgroundDimView : Border
{
    public BackgroundDimView()
    {
        // Must never intercept mouse events -- the drawing canvas stacked
        // on top of this in the same Grid cell is what should receive them.
        IsHitTestVisible = false;
    }

    private double _dimOpacity;

    public double DimOpacity
    {
        get => _dimOpacity;
        set
        {
            _dimOpacity = value;
            Background = new SolidColorBrush(Color.FromArgb((byte)(value * 255), 0, 0, 0));
        }
    }
}

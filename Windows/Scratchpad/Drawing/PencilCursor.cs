using System.IO;
using System.Windows.Input;

namespace Scratchpad.Drawing;

/// The cursor shown while the overlay is visible, replacing the system
/// arrow (SPEC.md: "Pencil cursor while drawing"). Uses the app's own
/// `drawing-icon.png`, pre-packaged as a real Windows `.cur` file
/// (`Resources/PencilCursor.cur`, a 32x32 PNG-format cursor image with a
/// hotspot near the pencil's tip) rather than converted from a bitmap at
/// runtime, since runtime `Icon.FromHandle`-style conversions lose the
/// PNG's alpha channel -- mirrors the macOS app's `PencilCursor`, which
/// loads the same source image into an `NSCursor`.
///
/// Unlike the macOS overlay window, WPF/Win32 has no "cursor only applies
/// to a key window" limitation: `UIElement.Cursor` is honored via
/// `WM_SETCURSOR` for any window under the pointer regardless of activation
/// state, so no tracking-area workaround is needed here.
///
/// `PencilCursor.Cursor` was hand-assembled offline (this repository was
/// authored on macOS, with no Windows machine available to verify a Windows
/// cursor loads correctly) by wrapping the resized source PNG directly in a
/// minimal ICONDIR/ICONDIRENTRY container -- the same PNG-payload-inside-ICO
/// mechanism Windows has supported for icons since Vista, which cursors
/// share the same on-disk format with. This has *not* been confirmed to
/// load on real Windows. The catch-all below exists specifically because of
/// that: if the `.cur` file turns out to be malformed, falling back to
/// `Cursors.Cross` is far better than a `TypeInitializationException`
/// crashing the whole app the first time this static field is touched.
public static class PencilCursor
{
    public static readonly Cursor Cursor = Load();

    private static Cursor Load()
    {
        var path = Path.Combine(AppContext.BaseDirectory, "Resources", "PencilCursor.cur");
        try
        {
            using var stream = File.OpenRead(path);
            return new Cursor(stream);
        }
        catch (Exception)
        {
            return Cursors.Cross;
        }
    }
}

using System.Windows;

namespace Scratchpad.Animations;

/// Fades a `Window` in or out. An interface so `OverlayWindowController` can
/// be tested without a real animation running. Mirrors the macOS app's
/// `OverlayFadeAnimator`.
public interface IOverlayFadeAnimator
{
    void FadeIn(Window window, TimeSpan duration);
    void FadeOut(Window window, TimeSpan duration, Action completion);
}

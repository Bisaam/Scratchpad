using System.Windows;
using System.Windows.Media.Animation;

namespace Scratchpad.Animations;

/// Animates via `DoubleAnimation` on `Window.Opacity`, with an ease-in/out
/// timing curve matching the subtle animation AppKit uses for its own
/// window animations -- mirrors the macOS app's `NSAnimationContextFadeAnimator`.
public sealed class WpfFadeAnimator : IOverlayFadeAnimator
{
    public void FadeIn(Window window, TimeSpan duration)
    {
        window.Opacity = 0;
        var animation = new DoubleAnimation(0, 1, duration)
        {
            EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseInOut },
        };
        window.BeginAnimation(UIElement.OpacityProperty, animation);
    }

    public void FadeOut(Window window, TimeSpan duration, Action completion)
    {
        var animation = new DoubleAnimation(window.Opacity, 0, duration)
        {
            EasingFunction = new QuadraticEase { EasingMode = EasingMode.EaseInOut },
        };
        animation.Completed += (_, _) => completion();
        window.BeginAnimation(UIElement.OpacityProperty, animation);
    }
}

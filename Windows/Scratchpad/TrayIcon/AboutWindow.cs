using System.Reflection;
using System.Windows;
using System.Windows.Controls;

namespace Scratchpad.TrayIcon;

/// A minimal "About Scratchpad" window. Windows has no system-provided
/// equivalent of AppKit's standard About panel
/// (`NSApp.orderFrontStandardAboutPanel`), so this is a small window built
/// directly in code -- not worth a separate XAML file for three lines of text.
public sealed class AboutWindow : Window
{
    public AboutWindow()
    {
        Title = "About Scratchpad";
        Width = 280;
        Height = 160;
        ResizeMode = ResizeMode.NoResize;
        WindowStartupLocation = WindowStartupLocation.CenterScreen;
        ShowInTaskbar = false;

        var version = Assembly.GetExecutingAssembly().GetName().Version?.ToString(3) ?? "0.1.0";
        var panel = new StackPanel
        {
            Margin = new Thickness(24),
            VerticalAlignment = VerticalAlignment.Center,
        };
        panel.Children.Add(new TextBlock
        {
            Text = "Scratchpad",
            FontSize = 20,
            FontWeight = FontWeights.SemiBold,
            HorizontalAlignment = HorizontalAlignment.Center,
        });
        panel.Children.Add(new TextBlock
        {
            Text = $"Version {version}",
            Margin = new Thickness(0, 8, 0, 0),
            HorizontalAlignment = HorizontalAlignment.Center,
        });
        panel.Children.Add(new TextBlock
        {
            Text = "A minimal fullscreen drawing overlay.",
            Margin = new Thickness(0, 8, 0, 0),
            HorizontalAlignment = HorizontalAlignment.Center,
            TextWrapping = TextWrapping.Wrap,
            TextAlignment = TextAlignment.Center,
        });
        Content = panel;
    }
}

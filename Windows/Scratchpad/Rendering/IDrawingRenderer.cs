using System.Windows.Controls;
using System.Windows.Shapes;
using Scratchpad.Drawing;

namespace Scratchpad.Rendering;

/// Renders strokes as shapes on a host `Canvas`, keeping the drawing
/// canvas's event handling (`DrawingCanvas`) separate from how a stroke
/// actually becomes pixels -- mirrors the macOS app's `DrawingRenderer`
/// protocol, which does the same for `CALayer`.
public interface IDrawingRenderer
{
    /// Adds a new shape for a completed stroke and returns it, so the caller
    /// can keep updating it while the stroke is still in progress.
    Path AddLayer(Stroke stroke, Canvas canvas);

    /// Re-renders an existing stroke's shape, called repeatedly while the
    /// user is still dragging.
    void UpdateLayer(Path layer, Stroke stroke);

    /// Removes every stroke shape, for "Clear Pad".
    void RemoveAllLayers(Canvas canvas);
}

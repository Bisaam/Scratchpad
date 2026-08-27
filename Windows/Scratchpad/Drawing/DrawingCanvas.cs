using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using Scratchpad.Rendering;
using MouseEventArgs = System.Windows.Input.MouseEventArgs;
using Point = System.Windows.Point;

namespace Scratchpad.Drawing;

/// The freehand drawing surface: tracks mouse events and turns them into
/// `DrawingStore` mutations, delegating the actual pixels to an
/// `IDrawingRenderer`. Mirrors the macOS app's `DrawingCanvasView`.
public sealed class DrawingCanvas : Canvas
{
    /// How close the eraser needs to pass to a stroke's path (in addition to
    /// that stroke's own half-width) to erase it.
    private const double EraserHitTestTolerance = 8;

    private readonly DrawingStore _store;
    private readonly IDrawingRenderer _renderer;
    private Path? _inProgressLayer;
    private readonly Dictionary<Guid, Path> _layersByStrokeId = new();

    public DrawingCanvas(DrawingStore store, IDrawingRenderer renderer)
    {
        _store = store;
        _renderer = renderer;
        // A Canvas with no background is transparent but not hit-testable;
        // Transparent (not null) makes the whole bounds receive mouse
        // events, mirroring the macOS view's opaque-to-hit-testing but
        // visually-transparent surface.
        Background = Brushes.Transparent;
        Focusable = false;
        RenderExistingStrokes();
    }

    protected override void OnMouseLeftButtonDown(MouseButtonEventArgs e)
    {
        CaptureMouse();
        var point = StrokePoint.FromWindowsPoint(e.GetPosition(this));
        _store.BeginStroke(point);
        if (_store.StrokeInProgress is { } stroke)
        {
            _inProgressLayer = _renderer.AddLayer(stroke, this);
        }
        e.Handled = true;
    }

    protected override void OnMouseMove(MouseEventArgs e)
    {
        if (e.RightButton == MouseButtonState.Pressed)
        {
            EraseStrokes(e.GetPosition(this));
            return;
        }
        if (_inProgressLayer is null || e.LeftButton != MouseButtonState.Pressed) return;
        var stroke = AppendPointAndGetStroke(e.GetPosition(this));
        if (stroke is not null)
        {
            _renderer.UpdateLayer(_inProgressLayer, stroke);
        }
    }

    protected override void OnMouseLeftButtonUp(MouseButtonEventArgs e)
    {
        if (_inProgressLayer is not null)
        {
            var stroke = AppendPointAndGetStroke(e.GetPosition(this));
            if (stroke is not null)
            {
                _renderer.UpdateLayer(_inProgressLayer, stroke);
                _layersByStrokeId[stroke.Id] = _inProgressLayer;
            }
        }
        _store.EndStroke();
        _inProgressLayer = null;
        ReleaseMouseCapture();
        e.Handled = true;
    }

    /// Holding right-click and dragging over a line erases that whole
    /// stroke -- there is no partial/pixel erasing in v0.1.
    protected override void OnMouseRightButtonDown(MouseButtonEventArgs e)
    {
        CaptureMouse();
        EraseStrokes(e.GetPosition(this));
        e.Handled = true;
    }

    protected override void OnMouseRightButtonUp(MouseButtonEventArgs e)
    {
        ReleaseMouseCapture();
        e.Handled = true;
    }

    /// Erases every stroke, both the persisted list and whatever is
    /// currently on screen. Overlay visibility is untouched by this call.
    public void ClearDrawing()
    {
        _store.Clear();
        _renderer.RemoveAllLayers(this);
        _layersByStrokeId.Clear();
    }

    private void EraseStrokes(Point point)
    {
        var erasedIds = _store.RemoveStrokes(StrokePoint.FromWindowsPoint(point), EraserHitTestTolerance);
        foreach (var id in erasedIds)
        {
            if (_layersByStrokeId.Remove(id, out var layer))
            {
                Children.Remove(layer);
            }
        }
    }

    private Stroke? AppendPointAndGetStroke(Point point)
    {
        _store.AppendPoint(StrokePoint.FromWindowsPoint(point));
        return _store.StrokeInProgress;
    }

    private void RenderExistingStrokes()
    {
        foreach (var stroke in _store.Strokes)
        {
            _layersByStrokeId[stroke.Id] = _renderer.AddLayer(stroke, this);
        }
    }
}

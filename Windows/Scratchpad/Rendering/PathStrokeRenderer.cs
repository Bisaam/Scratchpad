using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Shapes;
using Scratchpad.Drawing;

namespace Scratchpad.Rendering;

/// Renders each stroke as its own `Path` with a frozen `StreamGeometry`.
/// WPF retains and GPU-composites each `Path` once added, so only the
/// in-progress stroke's geometry is rebuilt per `MouseMove`, not the whole
/// canvas -- mirrors the macOS app's `CAShapeLayerStrokeRenderer`.
public sealed class PathStrokeRenderer : IDrawingRenderer
{
    public Path AddLayer(Stroke stroke, Canvas canvas)
    {
        var path = new Path();
        Configure(path, stroke);
        canvas.Children.Add(path);
        return path;
    }

    public void UpdateLayer(Path layer, Stroke stroke) => Configure(layer, stroke);

    public void RemoveAllLayers(Canvas canvas) => canvas.Children.Clear();

    private static void Configure(Path path, Stroke stroke)
    {
        path.Data = Geometry(stroke.Points);
        path.Stroke = Brush(stroke.Color);
        path.StrokeThickness = stroke.LineWidth;
        path.StrokeStartLineCap = PenLineCap.Round;
        path.StrokeEndLineCap = PenLineCap.Round;
        path.StrokeLineJoin = PenLineJoin.Round;
    }

    private static Geometry Geometry(IReadOnlyList<StrokePoint> points)
    {
        var geometry = new StreamGeometry();
        using (var context = geometry.Open())
        {
            var isOpen = false;
            foreach (var segment in StrokeSmoothing.Segments(points))
            {
                switch (segment)
                {
                    case PathSegment.Move move:
                        context.BeginFigure(move.To.ToWindowsPoint(), isFilled: false, isClosed: false);
                        isOpen = true;
                        break;
                    case PathSegment.Line line when isOpen:
                        context.LineTo(line.To.ToWindowsPoint(), isStroked: true, isSmoothJoin: true);
                        break;
                    case PathSegment.QuadCurve curve when isOpen:
                        context.QuadraticBezierTo(
                            curve.Control.ToWindowsPoint(),
                            curve.To.ToWindowsPoint(),
                            isStroked: true,
                            isSmoothJoin: true
                        );
                        break;
                }
            }
        }
        geometry.Freeze();
        return geometry;
    }

    private static SolidColorBrush Brush(StrokeColor color)
    {
        var brush = new SolidColorBrush(System.Windows.Media.Color.FromScRgb(
            (float)color.Alpha, (float)color.Red, (float)color.Green, (float)color.Blue));
        brush.Freeze();
        return brush;
    }
}

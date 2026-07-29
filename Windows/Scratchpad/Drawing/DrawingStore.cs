using System.Windows.Threading;
using Scratchpad.Overlay;
using Scratchpad.Persistence;

namespace Scratchpad.Drawing;

/// Owns the strokes for a single display: the freehand drawing business
/// logic, with no knowledge of whether or how it is currently rendered, and
/// no knowledge of whether the overlay is visible. Overlay visibility and
/// drawing content are deliberately independent (see `OverlayState`).
/// Mirrors the macOS app's `DrawingStore`.
public sealed class DrawingStore
{
    private readonly DisplayIdentifier _display;
    private readonly IDrawingRepository _repository;
    private readonly DispatcherTimer _saveDebounceTimer;
    private StrokeColor _defaultColor;
    private double _defaultLineWidth;

    public IReadOnlyList<Stroke> Strokes => _strokes;
    private readonly List<Stroke> _strokes;

    public Stroke? StrokeInProgress { get; private set; }

    public DrawingStore(
        DisplayIdentifier display,
        IDrawingRepository repository,
        StrokeColor? defaultColor = null,
        double defaultLineWidth = Stroke.DefaultLineWidth,
        TimeSpan? saveDebounceInterval = null)
    {
        _display = display;
        _repository = repository;
        _defaultColor = defaultColor ?? StrokeColor.Default;
        _defaultLineWidth = defaultLineWidth;
        _strokes = repository.Load(display).Strokes;

        // Debounced so a long stroke with hundreds of points, or "Clear Pad"
        // hit repeatedly, does not write to disk more than a few times a
        // second -- there is no need for every mutation to hit the
        // filesystem. Mirrors the macOS app's `DispatchWorkItem` debounce.
        _saveDebounceTimer = new DispatcherTimer { Interval = saveDebounceInterval ?? TimeSpan.FromMilliseconds(500) };
        _saveDebounceTimer.Tick += (_, _) =>
        {
            _saveDebounceTimer.Stop();
            SaveNow();
        };
    }

    /// Applied to strokes started from now on, not to strokes already
    /// drawn -- so changing the pencil color/thickness in Preferences never
    /// rewrites history, only affects what you draw next.
    public void UpdateDefaultStyle(StrokeColor color, double lineWidth)
    {
        _defaultColor = color;
        _defaultLineWidth = lineWidth;
    }

    public void BeginStroke(StrokePoint point)
    {
        StrokeInProgress = new Stroke
        {
            Points = new List<StrokePoint> { point },
            Color = _defaultColor,
            LineWidth = _defaultLineWidth,
        };
    }

    public void AppendPoint(StrokePoint point) => StrokeInProgress?.Points.Add(point);

    public void EndStroke()
    {
        var stroke = StrokeInProgress;
        StrokeInProgress = null;
        if (stroke is null || stroke.Points.Count == 0) return;
        _strokes.Add(stroke);
        ScheduleSave();
    }

    public void Clear()
    {
        _strokes.Clear();
        StrokeInProgress = null;
        ScheduleSave();
    }

    /// Removes every *whole* stroke passing within `tolerance` of `point`
    /// (plus that stroke's own half-width, so thicker strokes are easier to
    /// touch), and returns their ids so the caller can remove the matching
    /// rendered shapes. There is no partial/pixel erasing in v0.1.
    public IReadOnlyList<Guid> RemoveStrokes(StrokePoint point, double tolerance)
    {
        var matches = _strokes
            .Where(stroke => StrokeGeometry.MinimumDistance(point, stroke.Points) <= tolerance + stroke.LineWidth / 2)
            .ToList();
        if (matches.Count == 0) return Array.Empty<Guid>();

        var matchedIds = matches.Select(stroke => stroke.Id).ToHashSet();
        _strokes.RemoveAll(stroke => matchedIds.Contains(stroke.Id));
        ScheduleSave();
        return matches.Select(stroke => stroke.Id).ToList();
    }

    private void ScheduleSave()
    {
        _saveDebounceTimer.Stop();
        _saveDebounceTimer.Start();
    }

    private void SaveNow()
    {
        var document = new DrawingDocument { Strokes = _strokes.ToList(), UpdatedAt = DateTimeOffset.Now };
        try
        {
            _repository.Save(document, _display);
        }
        catch (Exception)
        {
            // Best-effort persistence, same as the macOS app's `try?` --
            // losing a debounced save to a transient disk error should not
            // crash an always-on-top drawing overlay.
        }
    }
}

using Scratchpad.Drawing;
using Scratchpad.Overlay;

namespace Scratchpad.Persistence;

/// Loads and saves the drawing for a single display.
///
/// Backed by plain JSON files rather than a database: drawings are just an
/// ordered stroke list, and JSON is what the macOS app already uses for the
/// same reason (trivial to read/write from either platform, no shared-format
/// requirement between them). Mirrors the macOS app's `DrawingRepository`.
public interface IDrawingRepository
{
    DrawingDocument Load(DisplayIdentifier display);
    void Save(DrawingDocument document, DisplayIdentifier display);
    void Clear(DisplayIdentifier display);
}

using Scratchpad.Overlay;
using Scratchpad.Persistence;

namespace Scratchpad.Drawing;

/// Creates and retains one `DrawingStore` per display, since v0.1 shows the
/// overlay on every connected monitor simultaneously and each screen's
/// drawing is independent (see `DisplayIdentifier`). Mirrors the macOS
/// app's `DrawingStoreFactory`.
public sealed class DrawingStoreFactory
{
    private readonly IDrawingRepository _repository;
    private readonly Dictionary<DisplayIdentifier, DrawingStore> _storesByDisplay = new();

    public DrawingStoreFactory(IDrawingRepository repository)
    {
        _repository = repository;
    }

    public DrawingStore Store(DisplayIdentifier display)
    {
        if (_storesByDisplay.TryGetValue(display, out var existing)) return existing;
        var store = new DrawingStore(display, _repository);
        _storesByDisplay[display] = store;
        return store;
    }

    public void RemoveStore(DisplayIdentifier display) => _storesByDisplay.Remove(display);

    public IReadOnlyList<DrawingStore> AllStores => _storesByDisplay.Values.ToList();
}

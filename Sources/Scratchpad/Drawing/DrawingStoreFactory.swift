/// Creates and retains one `DrawingStore` per display, since v0.1 shows the
/// overlay on every connected monitor simultaneously and each screen's
/// drawing is independent (see DisplayIdentifier).
final class DrawingStoreFactory {
    private let repository: DrawingRepository
    private var storesByDisplay: [DisplayIdentifier: DrawingStore] = [:]

    init(repository: DrawingRepository) {
        self.repository = repository
    }

    func store(for display: DisplayIdentifier) -> DrawingStore {
        if let existing = storesByDisplay[display] {
            return existing
        }
        let store = DrawingStore(display: display, repository: repository)
        storesByDisplay[display] = store
        return store
    }

    func removeStore(for display: DisplayIdentifier) {
        storesByDisplay.removeValue(forKey: display)
    }

    var allStores: [DrawingStore] {
        Array(storesByDisplay.values)
    }
}

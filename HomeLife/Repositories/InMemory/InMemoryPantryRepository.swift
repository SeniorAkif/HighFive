import Foundation

/// Bellek içi buzdolabı & kiler deposu (önizleme ve testler için)
public final class InMemoryPantryRepository: PantryRepositoryProtocol {
    private var items: [PantryItem]

    public init(initialItems: [PantryItem] = MockDataFactory.createPantryItems()) {
        self.items = initialItems
    }

    public func fetchAll() async throws -> [PantryItem] {
        items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    public func fetch(by id: UUID) async throws -> PantryItem? {
        items.first { $0.id == id }
    }

    public func add(_ item: PantryItem) async throws {
        items.append(item)
    }

    public func update(_ item: PantryItem) async throws {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        }
    }

    public func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }
}

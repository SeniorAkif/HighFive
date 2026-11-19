import Foundation
import SwiftUI

/// Saklama yerine göre üst filtre
public enum PantryLocationFilter: Hashable, Identifiable, CaseIterable {
    case all
    case location(PantryStorageLocation)

    public static var allCases: [PantryLocationFilter] {
        [.all] + PantryStorageLocation.allCases.map { .location($0) }
    }

    public var id: String {
        switch self {
        case .all: return "all"
        case .location(let location): return location.rawValue
        }
    }

    public var localizedTitle: String {
        switch self {
        case .all:
            return LanguageManager.shared.locale.identifier.starts(with: "tr") ? "Tümü" : "All"
        case .location(let location):
            return location.localizedTitle
        }
    }
}

@MainActor
public final class PantryViewModel: ObservableObject {
    @Published public var items: [PantryItem] = []
    @Published public var roommates: [Roommate] = []
    @Published public var searchText: String = ""
    @Published public var selectedLocation: PantryLocationFilter = .all
    /// nil = tüm kategoriler
    @Published public var selectedCategory: PantryCategory?
    @Published public var showOnlyExpiring: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var isShowingAddSheet: Bool = false
    /// Düzenleme için açılan ürün
    @Published public var editingItem: PantryItem?
    /// Miktarı sıfıra düşen ve kullanıcıdan "kaldır / tut" kararı beklenen ürün
    @Published public var depletedItem: PantryItem?

    private let pantryRepository: any PantryRepositoryProtocol
    private let roommateRepository: any RoommateRepositoryProtocol

    public init(
        pantryRepository: any PantryRepositoryProtocol,
        roommateRepository: any RoommateRepositoryProtocol
    ) {
        self.pantryRepository = pantryRepository
        self.roommateRepository = roommateRepository
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedItems = pantryRepository.fetchAll()
            async let fetchedRoommates = roommateRepository.fetchAll()

            let (i, r) = try await (fetchedItems, fetchedRoommates)
            self.items = i
            self.roommates = r
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Filtreleme & Sıralama

    /// Arama, saklama yeri ve kategori filtrelerinden geçen ürünler.
    /// SKT'si geçmiş/yaklaşan ürünler en üstte, tükenenler en altta listelenir.
    public var filteredItems: [PantryItem] {
        let now = Date()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        return items
            .filter { item in
                if case .location(let location) = selectedLocation, item.location != location { return false }
                if let selectedCategory, item.category != selectedCategory { return false }
                if showOnlyExpiring, !item.expiryStatus(from: now).needsAttention { return false }
                if !query.isEmpty, !item.name.localizedStandardContains(query) { return false }
                return true
            }
            .sorted { lhs, rhs in
                if lhs.isDepleted != rhs.isDepleted { return !lhs.isDepleted }
                let lhsStatus = lhs.expiryStatus(from: now)
                let rhsStatus = rhs.expiryStatus(from: now)
                if lhsStatus != rhsStatus { return lhsStatus < rhsStatus }
                if let l = lhs.expirationDate, let r = rhs.expirationDate, l != r { return l < r }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    /// SKT'si geçmiş veya yaklaşan (tükenmemiş) ürünler
    public var expiringItems: [PantryItem] {
        let now = Date()
        return items.filter { !$0.isDepleted && $0.expiryStatus(from: now).needsAttention }
    }

    public var expiredCount: Int {
        let now = Date()
        return expiringItems.filter { $0.expiryStatus(from: now) == .expired }.count
    }

    /// Seçili saklama yerinde bulunan kategoriler (filtre çiplerinde gösterilir)
    public var availableCategories: [PantryCategory] {
        let scoped: [PantryItem]
        if case .location(let location) = selectedLocation {
            scoped = items.filter { $0.location == location }
        } else {
            scoped = items
        }
        let present = Set(scoped.map(\.category))
        return PantryCategory.allCases.filter { present.contains($0) }
    }

    public var hasActiveFilters: Bool {
        selectedCategory != nil || showOnlyExpiring || !searchText.isEmpty || selectedLocation != .all
    }

    public func clearFilters() {
        selectedCategory = nil
        showOnlyExpiring = false
        searchText = ""
        selectedLocation = .all
    }

    public func roommate(for id: UUID?) -> Roommate? {
        guard let id else { return nil }
        return roommates.first { $0.id == id }
    }

    // MARK: - CRUD

    public func addItem(_ item: PantryItem) async {
        do {
            try await pantryRepository.add(item)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updateItem(_ item: PantryItem) async {
        var updated = item
        updated.updatedAt = Date()
        await persist(updated)
    }

    public func deleteItem(_ item: PantryItem) async {
        let snapshot = items
        items.removeAll { $0.id == item.id }
        do {
            try await pantryRepository.delete(id: item.id)
        } catch {
            items = snapshot
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Hızlı Miktar Değişimi

    /// Miktarı birimin adım değeri kadar artırır
    public func increment(_ item: PantryItem) async {
        guard let current = currentItem(item) else { return }
        var updated = current
        updated.quantity = Self.rounded(current.quantity + current.unit.quickStep)
        updated.updatedAt = Date()
        await persist(updated)
    }

    /// Miktarı birimin adım değeri kadar azaltır; sıfıra düşerse kullanıcıya kaldırma seçeneği sunar
    public func decrement(_ item: PantryItem) async {
        guard let current = currentItem(item), !current.isDepleted else { return }
        var updated = current
        updated.quantity = max(0, Self.rounded(current.quantity - current.unit.quickStep))
        updated.updatedAt = Date()
        let saved = await persist(updated)

        if saved, updated.isDepleted {
            depletedItem = updated
        }
    }

    /// Tükenen ürünü listeden kaldırır
    public func removeDepletedItem() async {
        guard let item = depletedItem else { return }
        depletedItem = nil
        await deleteItem(item)
    }

    /// Tükenen ürünü "Tükendi" olarak listede tutar
    public func keepDepletedItem() {
        depletedItem = nil
    }

    // MARK: - Private

    /// Arayüzdeki satır eski bir kopyayı tutuyor olabilir; en güncel değeri listeden alır
    private func currentItem(_ item: PantryItem) -> PantryItem? {
        items.first { $0.id == item.id }
    }

    /// Önce yerelde günceller (anında geri bildirim), hata olursa eski değere döner
    @discardableResult
    private func persist(_ updated: PantryItem) async -> Bool {
        guard let index = items.firstIndex(where: { $0.id == updated.id }) else { return false }
        let previous = items[index]
        items[index] = updated
        do {
            try await pantryRepository.update(updated)
            return true
        } catch {
            if let revertIndex = items.firstIndex(where: { $0.id == updated.id }) {
                items[revertIndex] = previous
            }
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// 0.1 + 0.2 gibi kayan nokta hatalarını temizler
    private static func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

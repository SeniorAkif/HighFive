import SwiftUI

/// Akıllı Buzdolabı & Kiler ana ekranı
public struct PantryView: View {
    @EnvironmentObject private var container: DependencyContainer
    @ObservedObject private var languageManager = LanguageManager.shared
    @StateObject private var viewModel: PantryViewModel

    public init(container: DependencyContainer) {
        _viewModel = StateObject(
            wrappedValue: PantryViewModel(
                pantryRepository: container.pantryRepository,
                roommateRepository: container.roommateRepository
            )
        )
    }

    private var isTurkish: Bool {
        LanguageManager.shared.locale.identifier.starts(with: "tr")
    }

    /// Yeni ürün eklerken seçili saklama yeri varsayılan olarak kullanılır
    private var defaultLocationForNewItem: PantryStorageLocation? {
        if case .location(let location) = viewModel.selectedLocation { return location }
        return nil
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterHeader

                if !viewModel.expiringItems.isEmpty {
                    expiryBanner
                }

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.filteredItems.isEmpty {
                            emptyState
                                .padding(.top, 24)
                        } else {
                            ForEach(viewModel.filteredItems) { item in
                                PantryItemRowView(
                                    item: item,
                                    addedBy: container.houseMode == .shared ? viewModel.roommate(for: item.addedByRoommateId) : nil,
                                    onIncrement: {
                                        Task { await viewModel.increment(item) }
                                    },
                                    onDecrement: {
                                        Task { await viewModel.decrement(item) }
                                    },
                                    onEdit: {
                                        viewModel.editingItem = item
                                    },
                                    onDelete: {
                                        Task { await viewModel.deleteItem(item) }
                                    }
                                )
                            }
                        }
                    }
                    .padding(16)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.filteredItems.map(\.id))
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Buzdolabı & Kiler")
            .searchable(text: $viewModel.searchText, prompt: Text("Ürün ara"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.primary)
                    }
                    .accessibilityLabel(Text("Yeni Ürün Ekle"))
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                AddPantryItemSheet(
                    roommates: viewModel.roommates,
                    preferredRoommateId: container.currentRoommateId,
                    houseMode: container.houseMode,
                    defaultLocation: defaultLocationForNewItem
                ) { newItem in
                    Task { await viewModel.addItem(newItem) }
                }
            }
            .sheet(item: $viewModel.editingItem) { item in
                AddPantryItemSheet(
                    roommates: viewModel.roommates,
                    preferredRoommateId: container.currentRoommateId,
                    houseMode: container.houseMode,
                    existingItem: item
                ) { updated in
                    Task { await viewModel.updateItem(updated) }
                }
            }
            .confirmationDialog(
                depletedDialogTitle,
                isPresented: Binding(
                    get: { viewModel.depletedItem != nil },
                    set: { isPresented in
                        if !isPresented { viewModel.keepDepletedItem() }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("Listeden Kaldır", role: .destructive) {
                    Task { await viewModel.removeDepletedItem() }
                }
                Button("Listede Tut (Tükendi)") {
                    viewModel.keepDepletedItem()
                }
            } message: {
                Text("Ürünün miktarı sıfıra düştü. Listeden kaldırabilir veya tekrar almak için “Tükendi” olarak tutabilirsin.")
            }
            .task {
                await viewModel.loadData()
            }
            .onChange(of: viewModel.isShowingAddSheet) { _, isShowing in
                // Sheet açılırken ev arkadaşı listesi boşsa yeniden yükle
                if isShowing && viewModel.roommates.isEmpty {
                    Task { await viewModel.loadData() }
                }
            }
            .refreshable {
                await viewModel.loadData()
            }
            .onChange(of: container.activeHouseId) { _, _ in
                // Oturum/ev hazır olduğunda (veya yeniden denendiğinde) verileri tazele
                Task { await viewModel.loadData() }
            }
            .errorAlert($viewModel.errorMessage)
        }
    }

    private var depletedDialogTitle: String {
        let name = viewModel.depletedItem?.name ?? ""
        return isTurkish ? "\(name) bitti" : "\(name) is out"
    }

    // MARK: - Filtreler

    private var filterHeader: some View {
        VStack(spacing: 10) {
            Picker("Saklama Yeri", selection: $viewModel.selectedLocation) {
                ForEach(PantryLocationFilter.allCases) { filter in
                    Text(filter.localizedTitle).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: isTurkish ? "Tüm Kategoriler" : "All Categories",
                        isSelected: viewModel.selectedCategory == nil
                    ) {
                        viewModel.selectedCategory = nil
                    }

                    ForEach(viewModel.availableCategories) { category in
                        FilterChip(
                            title: "\(category.emoji) \(category.localizedTitle)",
                            color: Color(hex: category.colorHex),
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            viewModel.selectedCategory = viewModel.selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.cardBackground)
    }

    /// SKT'si geçmiş/yaklaşan ürünler için uyarı; dokununca yalnızca bu ürünleri gösterir
    private var expiryBanner: some View {
        let hasExpired = viewModel.expiredCount > 0
        let tint = hasExpired ? AppTheme.danger : AppTheme.warning
        let count = viewModel.expiringItems.count

        return Button {
            withAnimation { viewModel.showOnlyExpiring.toggle() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: hasExpired ? "exclamationmark.triangle.fill" : "clock.badge.exclamationmark.fill")
                    .foregroundColor(tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isTurkish ? "\(count) ürünün SKT'si dolmak üzere" : "\(count) \(count == 1 ? "item is" : "items are") expiring soon")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(tint)

                    Text(bannerSubtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(viewModel.showOnlyExpiring ? (isTurkish ? "Tümünü Göster" : "Show All") : (isTurkish ? "Göster" : "Show"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(tint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(tint.opacity(0.12))
        }
        .buttonStyle(.plain)
    }

    private var bannerSubtitle: String {
        let expired = viewModel.expiredCount
        if expired > 0 {
            return isTurkish
                ? "\(expired) ürünün SKT'si geçti. Önce bunları kontrol et."
                : "\(expired) \(expired == 1 ? "item has" : "items have") expired. Check these first."
        }
        return isTurkish
            ? "Önümüzdeki \(PantryExpiryStatus.soonThresholdDays) gün içinde tüketilmesi gerekenler var."
            : "Some items should be used within \(PantryExpiryStatus.soonThresholdDays) days."
    }

    @ViewBuilder
    private var emptyState: some View {
        if viewModel.items.isEmpty {
            EmptyStateView(
                icon: "refrigerator",
                title: "Buzdolabı Boş",
                message: "Buzdolabı ve kilerdeki ürünleri ekleyerek neyin bittiğini ve SKT'si yaklaşanları takip et.",
                actionTitle: "Ürün Ekle"
            ) {
                viewModel.isShowingAddSheet = true
            }
        } else {
            EmptyStateView(
                icon: "magnifyingglass",
                title: "Ürün Bulunamadı",
                message: "Arama veya filtrelere uygun ürün yok.",
                actionTitle: "Filtreleri Temizle"
            ) {
                viewModel.clearFilters()
            }
        }
    }
}

/// Yatay kaydırmalı filtre çipi
private struct FilterChip: View {
    let title: String
    var color: Color = AppTheme.primary
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.primary.opacity(0.06))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

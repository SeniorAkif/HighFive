import SwiftUI

public struct ChoresView: View {
    @StateObject private var viewModel: ChoresViewModel

    public init(container: DependencyContainer) {
        _viewModel = StateObject(
            wrappedValue: ChoresViewModel(
                choreRepository: container.choreRepository,
                roommateRepository: container.roommateRepository
            )
        )
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtreleme Çubuğu
                filterBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.cardBackground)

                // Görev Listesi
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.filteredChores.isEmpty {
                            EmptyStateView(
                                icon: "checkmark.seal",
                                title: "Görev Bulunamadı",
                                message: "Bu filtreye uygun herhangi bir ev işi bulunmuyor.",
                                actionTitle: "Yeni Görev Ekle"
                            ) {
                                viewModel.isShowingAddSheet = true
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(viewModel.filteredChores) { chore in
                                ChoreRowView(
                                    chore: chore,
                                    roommates: viewModel.roommates,
                                    onComplete: {
                                        Task {
                                            await viewModel.completeChore(chore)
                                        }
                                    },
                                    onSkip: {
                                        Task {
                                            await viewModel.skipTurn(chore, reason: "Manuel sıra atlama")
                                        }
                                    },
                                    onViewHistory: {
                                        viewModel.selectedChoreForHistory = chore
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteChore(chore)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Ev İşleri Sıralaması")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                AddChoreSheet(roommates: viewModel.roommates) { title, desc, cat, order, freq, date in
                    Task {
                        await viewModel.addChore(
                            title: title,
                            description: desc,
                            category: cat,
                            rotationOrder: order,
                            frequency: freq,
                            firstDueDate: date
                        )
                    }
                }
            }
            .sheet(item: $viewModel.selectedChoreForHistory) { chore in
                ChoreHistorySheet(
                    chore: chore,
                    logs: viewModel.logsForChore(chore),
                    roommates: viewModel.roommates
                )
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            Picker("Filtrele", selection: $viewModel.selectedFilter) {
                ForEach(ChoreFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            // Eğer "Sırası Gelenler" seçildiyse, kişi seçici göster
            if viewModel.selectedFilter == .mine {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            viewModel.selectedRoommateFilter = nil
                        } label: {
                            Text("Tüm Kişiler")
                                .font(.caption)
                                .fontWeight(viewModel.selectedRoommateFilter == nil ? .bold : .regular)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(viewModel.selectedRoommateFilter == nil ? AppTheme.primary : Color.primary.opacity(0.06))
                                .foregroundColor(viewModel.selectedRoommateFilter == nil ? .white : .primary)
                                .cornerRadius(12)
                        }

                        ForEach(viewModel.roommates) { roommate in
                            let isSelected = viewModel.selectedRoommateFilter == roommate.id
                            Button {
                                viewModel.selectedRoommateFilter = roommate.id
                            } label: {
                                HStack(spacing: 4) {
                                    AvatarBadgeView(
                                        emoji: roommate.avatarEmoji,
                                        initials: roommate.initials,
                                        colorHex: roommate.avatarColorHex,
                                        size: 20
                                    )
                                    Text(roommate.displayName)
                                        .font(.caption)
                                        .fontWeight(isSelected ? .bold : .regular)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isSelected ? Color(hex: roommate.avatarColorHex) : Color(hex: roommate.avatarColorHex).opacity(0.1))
                                .foregroundColor(isSelected ? .white : Color(hex: roommate.avatarColorHex))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
    }
}

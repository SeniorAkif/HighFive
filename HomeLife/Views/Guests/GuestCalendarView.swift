import SwiftUI

public struct GuestCalendarView: View {
    @StateObject private var viewModel: GuestCalendarViewModel

    public init(container: DependencyContainer) {
        _viewModel = StateObject(
            wrappedValue: GuestCalendarViewModel(
                guestRepository: container.guestRepository,
                roommateRepository: container.roommateRepository
            )
        )
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtreleme Çubuğu
                Picker("Filtrele", selection: $viewModel.selectedFilter) {
                    ForEach(GuestCalendarFilter.allCases) { filter in
                        Text(filter.localizedTitle).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.cardBackground)

                // Çakışma Uyarısı Banner'ı
                if !viewModel.conflictingVisits.isEmpty {
                    conflictBanner
                }

                // Misafir Listesi
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.filteredVisits.isEmpty {
                            EmptyStateView(
                                icon: "person.crop.circle.badge.plus",
                                title: "Kayıtlı Misafir Yok",
                                message: "Bu filtreye uygun herhangi bir misafir kaydı bulunmuyor.",
                                actionTitle: "Misafir Ekle"
                            ) {
                                viewModel.isShowingAddSheet = true
                            }
                            .padding(.top, 40)
                        } else {
                            ForEach(viewModel.filteredVisits) { visit in
                                GuestVisitRowView(
                                    visit: visit,
                                    host: viewModel.roommate(for: visit.hostRoommateId),
                                    onStatusChange: { newStatus in
                                        Task {
                                            await viewModel.updateStatus(for: visit, to: newStatus)
                                        }
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteVisit(visit)
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
            .navigationTitle("Misafir Takvimi")
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
                AddGuestSheet(roommates: viewModel.roommates) { hostId, name, count, start, end, isOvernight, location, notes in
                    Task {
                        await viewModel.addVisit(
                            hostRoommateId: hostId,
                            guestName: name,
                            guestCount: count,
                            startDate: start,
                            endDate: end,
                            isOvernight: isOvernight,
                            stayLocation: location,
                            notes: notes
                        )
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    private var conflictBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppTheme.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text("Misafir Çakışması Uyarısı!")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.danger)

                Text("Aynı tarihlere denk gelen birden fazla misafir ziyareti var. Ev durumunu teyit edin.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(AppTheme.danger.opacity(0.12))
    }
}

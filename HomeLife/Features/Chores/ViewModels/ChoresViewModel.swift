import Foundation
import SwiftUI

public enum ChoreFilter: String, CaseIterable, Identifiable {
    case all = "Tümü"
    case urgent = "Acil & Bugün"
    case mine = "Sırası Gelenler"

    public var id: String { rawValue }
}

@MainActor
public final class ChoresViewModel: ObservableObject {
    @Published public var chores: [Chore] = []
    @Published public var roommates: [Roommate] = []
    @Published public var logs: [ChoreLog] = []
    @Published public var selectedFilter: ChoreFilter = .all
    @Published public var selectedRoommateFilter: UUID? = nil
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var isShowingAddSheet: Bool = false
    @Published public var selectedChoreForHistory: Chore? = nil

    private let choreRepository: any ChoreRepositoryProtocol
    private let roommateRepository: any RoommateRepositoryProtocol

    public init(
        choreRepository: any ChoreRepositoryProtocol,
        roommateRepository: any RoommateRepositoryProtocol
    ) {
        self.choreRepository = choreRepository
        self.roommateRepository = roommateRepository
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedChores = choreRepository.fetchAll()
            async let fetchedRoommates = roommateRepository.fetchAll()
            async let fetchedLogs = choreRepository.fetchLogs(for: nil)

            let (c, r, l) = try await (fetchedChores, fetchedRoommates, fetchedLogs)
            self.chores = c
            self.roommates = r
            self.logs = l
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Filtrelenmiş görevler listesi
    public var filteredChores: [Chore] {
        var result = chores

        switch selectedFilter {
        case .all:
            break
        case .urgent:
            result = result.filter { $0.isOverdue || $0.isDueToday }
        case .mine:
            if let selectedRoommateFilter = selectedRoommateFilter {
                result = result.filter { $0.currentAssigneeId == selectedRoommateFilter }
            }
        }

        return result.sorted { $0.dueDate < $1.dueDate }
    }

    /// ID'ye göre ev arkadaşı
    public func roommate(for id: UUID?) -> Roommate? {
        guard let id = id else { return nil }
        return roommates.first { $0.id == id }
    }

    /// Görevi mevcut kişi adına tamamlar ve sıradakine geçirir
    public func completeChore(_ chore: Chore, notes: String? = nil) async {
        guard let assigneeId = chore.currentAssigneeId else { return }
        do {
            let updated = try await choreRepository.completeTurn(choreId: chore.id, completedById: assigneeId, notes: notes)
            if let index = chores.firstIndex(where: { $0.id == updated.id }) {
                chores[index] = updated
            }
            // Güncel logları çek
            self.logs = try await choreRepository.fetchLogs(for: nil)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Görev sırasını bir sonraki kişiye atlar
    public func skipTurn(_ chore: Chore, reason: String? = nil) async {
        do {
            let updated = try await choreRepository.skipTurn(choreId: chore.id, reason: reason)
            if let index = chores.firstIndex(where: { $0.id == updated.id }) {
                chores[index] = updated
            }
            self.logs = try await choreRepository.fetchLogs(for: nil)
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Yeni ev işi ekler
    public func addChore(
        title: String,
        description: String,
        category: ChoreCategory,
        rotationOrder: [UUID],
        frequency: ChoreFrequency,
        firstDueDate: Date
    ) async {
        let newChore = Chore(
            title: title,
            description: description,
            category: category,
            rotationOrder: rotationOrder,
            currentAssigneeIndex: 0,
            frequency: frequency,
            dueDate: firstDueDate
        )
        do {
            try await choreRepository.add(newChore)
            await loadData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Görevi siler
    public func deleteChore(_ chore: Chore) async {
        do {
            try await choreRepository.delete(id: chore.id)
            chores.removeAll { $0.id == chore.id }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Belirli bir görev için geçmiş kayıtları
    public func logsForChore(_ chore: Chore) -> [ChoreLog] {
        return logs.filter { $0.choreId == chore.id }
    }
}

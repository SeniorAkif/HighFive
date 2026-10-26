import Foundation
import SwiftUI

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var roommates: [Roommate] = []
    @Published public var chores: [Chore] = []
    @Published public var upcomingVisits: [GuestVisit] = []
    @Published public var activeVisits: [GuestVisit] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?

    private let roommateRepository: any RoommateRepositoryProtocol
    private let choreRepository: any ChoreRepositoryProtocol
    private let guestRepository: any GuestRepositoryProtocol

    public init(
        roommateRepository: any RoommateRepositoryProtocol,
        choreRepository: any ChoreRepositoryProtocol,
        guestRepository: any GuestRepositoryProtocol
    ) {
        self.roommateRepository = roommateRepository
        self.choreRepository = choreRepository
        self.guestRepository = guestRepository
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedRoommates = roommateRepository.fetchAll()
            async let fetchedChores = choreRepository.fetchAll()
            async let fetchedVisits = guestRepository.fetchAll()

            let (r, c, v) = try await (fetchedRoommates, fetchedChores, fetchedVisits)
            self.roommates = r
            self.chores = c
            
            // Misafirleri sınıflandır
            let now = Date()
            self.activeVisits = v.filter { $0.startDate <= now && now <= $0.endDate && $0.status != .cancelled }
            self.upcomingVisits = v.filter { $0.startDate > now && $0.status == .upcoming }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Bugün yapılması gereken veya gecikmiş görevler
    public var urgentChores: [Chore] {
        chores.filter { $0.isOverdue || $0.isDueToday }
            .sorted { $0.dueDate < $1.dueDate }
    }

    /// Sıradaki yaklaşan görevler (en fazla 5)
    public var upcomingChores: [Chore] {
        chores.sorted { $0.dueDate < $1.dueDate }
    }

    /// ID'ye göre ev arkadaşını bulur
    public func roommate(for id: UUID?) -> Roommate? {
        guard let id = id else { return nil }
        return roommates.first { $0.id == id }
    }

    /// Dashboard üzerinden görevi hızlıca tamamlama
    public func completeChore(_ chore: Chore) async {
        guard let assigneeId = chore.currentAssigneeId else { return }
        do {
            let updated = try await choreRepository.completeTurn(choreId: chore.id, completedById: assigneeId, notes: "Dashboard üzerinden tamamlandı")
            if let index = chores.firstIndex(where: { $0.id == updated.id }) {
                chores[index] = updated
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

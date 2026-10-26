import Foundation
import SwiftUI

public enum GuestCalendarFilter: String, CaseIterable, Identifiable {
    case upcoming = "Yaklaşanlar"
    case active = "Evde Olanlar"
    case all = "Tüm Kayıtlar"

    public var id: String { rawValue }

    public var localizedTitle: String {
        let isTurkish = LanguageManager.shared.locale.identifier.starts(with: "tr")
        switch self {
        case .upcoming: return isTurkish ? "Yaklaşanlar" : "Upcoming"
        case .active: return isTurkish ? "Evde Olanlar" : "At Home"
        case .all: return isTurkish ? "Tüm Kayıtlar" : "All"
        }
    }
}

@MainActor
public final class GuestCalendarViewModel: ObservableObject {
    @Published public var visits: [GuestVisit] = []
    @Published public var roommates: [Roommate] = []
    @Published public var selectedFilter: GuestCalendarFilter = .upcoming
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var isShowingAddSheet: Bool = false

    private let guestRepository: any GuestRepositoryProtocol
    private let roommateRepository: any RoommateRepositoryProtocol

    public init(
        guestRepository: any GuestRepositoryProtocol,
        roommateRepository: any RoommateRepositoryProtocol
    ) {
        self.guestRepository = guestRepository
        self.roommateRepository = roommateRepository
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedVisits = guestRepository.fetchAll()
            async let fetchedRoommates = roommateRepository.fetchAll()

            let (v, r) = try await (fetchedVisits, fetchedRoommates)
            self.visits = v
            self.roommates = r
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Çakışan misafir ziyaretleri listesi (farklı ev arkadaşlarının aynı tarihe denk gelen misafirleri)
    public var conflictingVisits: [(GuestVisit, GuestVisit)] {
        var conflicts: [(GuestVisit, GuestVisit)] = []
        for i in 0..<visits.count {
            for j in (i + 1)..<visits.count {
                let v1 = visits[i]
                let v2 = visits[j]
                if v1.overlaps(with: v2) {
                    conflicts.append((v1, v2))
                }
            }
        }
        return conflicts
    }

    /// Filtrelenmiş ziyaretler
    public var filteredVisits: [GuestVisit] {
        let now = Date()
        switch selectedFilter {
        case .upcoming:
            return visits.filter { $0.startDate >= now && $0.status != .cancelled }
                .sorted { $0.startDate < $1.startDate }
        case .active:
            return visits.filter { $0.isCurrentlyActive }
                .sorted { $0.startDate < $1.startDate }
        case .all:
            return visits.sorted { $0.startDate < $1.startDate }
        }
    }

    /// ID'ye göre ev arkadaşı
    public func roommate(for id: UUID) -> Roommate? {
        roommates.first { $0.id == id }
    }

    /// Yeni misafir ekler
    public func addVisit(
        hostRoommateId: UUID,
        guestName: String,
        guestCount: Int,
        startDate: Date,
        endDate: Date,
        isOvernight: Bool,
        stayLocation: String,
        notes: String
    ) async {
        let newVisit = GuestVisit(
            hostRoommateId: hostRoommateId,
            guestName: guestName,
            guestCount: guestCount,
            startDate: startDate,
            endDate: endDate,
            isOvernight: isOvernight,
            stayLocation: stayLocation,
            notes: notes,
            status: .upcoming
        )
        do {
            try await guestRepository.add(newVisit)
            await loadData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Misafir durumunu günceller
    public func updateStatus(for visit: GuestVisit, to newStatus: GuestVisitStatus) async {
        var updated = visit
        updated.status = newStatus
        do {
            try await guestRepository.update(updated)
            if let index = visits.firstIndex(where: { $0.id == visit.id }) {
                visits[index] = updated
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Misafir kaydını siler
    public func deleteVisit(_ visit: GuestVisit) async {
        do {
            try await guestRepository.delete(id: visit.id)
            visits.removeAll { $0.id == visit.id }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

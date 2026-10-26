import Foundation

/// Bellek içi misafir takvimi deposu
public final class InMemoryGuestRepository: GuestRepositoryProtocol {
    private var visits: [GuestVisit]

    public init(initialVisits: [GuestVisit] = MockDataFactory.createGuestVisits()) {
        self.visits = initialVisits
    }

    public func fetchAll() async throws -> [GuestVisit] {
        return visits.sorted { $0.startDate < $1.startDate }
    }

    public func fetch(by id: UUID) async throws -> GuestVisit? {
        return visits.first { $0.id == id }
    }

    public func add(_ visit: GuestVisit) async throws {
        visits.append(visit)
    }

    public func update(_ visit: GuestVisit) async throws {
        if let index = visits.firstIndex(where: { $0.id == visit.id }) {
            visits[index] = visit
        }
    }

    public func delete(id: UUID) async throws {
        visits.removeAll { $0.id == id }
    }

    public func fetchVisits(from startDate: Date, to endDate: Date) async throws -> [GuestVisit] {
        return visits.filter { visit in
            visit.startDate <= endDate && visit.endDate >= startDate
        }
    }
}

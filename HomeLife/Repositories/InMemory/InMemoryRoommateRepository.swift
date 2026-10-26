import Foundation

/// Bellek içi ev arkadaşı deposu (Test, Geliştirme ve Mock için)
public final class InMemoryRoommateRepository: RoommateRepositoryProtocol {
    private var roommates: [Roommate]

    public init(initialRoommates: [Roommate] = MockDataFactory.createRoommates()) {
        self.roommates = initialRoommates
    }

    public func fetchAll() async throws -> [Roommate] {
        return roommates
    }

    public func fetch(by id: UUID) async throws -> Roommate? {
        return roommates.first { $0.id == id }
    }

    public func add(_ roommate: Roommate) async throws {
        roommates.append(roommate)
    }

    public func update(_ roommate: Roommate) async throws {
        if let index = roommates.firstIndex(where: { $0.id == roommate.id }) {
            roommates[index] = roommate
        }
    }

    public func delete(id: UUID) async throws {
        roommates.removeAll { $0.id == id }
    }
}

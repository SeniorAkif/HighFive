import Foundation

/// Ev arkadaşları veri erişim protokolü
public protocol RoommateRepositoryProtocol: AnyObject {
    func fetchAll() async throws -> [Roommate]
    func fetch(by id: UUID) async throws -> Roommate?
    func add(_ roommate: Roommate) async throws
    func update(_ roommate: Roommate) async throws
    func delete(id: UUID) async throws
}

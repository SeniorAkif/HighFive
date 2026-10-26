import Foundation

/// Misafir takvimi yönetim protokolü
public protocol GuestRepositoryProtocol: AnyObject {
    func fetchAll() async throws -> [GuestVisit]
    func fetch(by id: UUID) async throws -> GuestVisit?
    func add(_ visit: GuestVisit) async throws
    func update(_ visit: GuestVisit) async throws
    func delete(id: UUID) async throws
    
    /// Belirli bir tarih aralığındaki misafirleri listeler
    func fetchVisits(from startDate: Date, to endDate: Date) async throws -> [GuestVisit]
}

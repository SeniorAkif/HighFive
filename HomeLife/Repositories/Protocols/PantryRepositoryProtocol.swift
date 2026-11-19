import Foundation

/// Akıllı Buzdolabı & Kiler ürün yönetim protokolü
public protocol PantryRepositoryProtocol: AnyObject {
    func fetchAll() async throws -> [PantryItem]
    func fetch(by id: UUID) async throws -> PantryItem?
    func add(_ item: PantryItem) async throws
    func update(_ item: PantryItem) async throws
    func delete(id: UUID) async throws
}

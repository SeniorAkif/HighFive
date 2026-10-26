import Foundation

/// Ev işleri ve tur döngüsü yönetim protokolü
public protocol ChoreRepositoryProtocol: AnyObject {
    func fetchAll() async throws -> [Chore]
    func fetch(by id: UUID) async throws -> Chore?
    func add(_ chore: Chore) async throws
    func update(_ chore: Chore) async throws
    func delete(id: UUID) async throws
    
    /// Görevi mevcut kişi için tamamlar, sıradaki ev arkadaşına devreder ve log kaydeder
    func completeTurn(choreId: UUID, completedById: UUID, notes: String?) async throws -> Chore
    
    /// Görev sırasını bir sonraki kişiye atlar (örn. sınavı/seyahati olan ev arkadaşı için)
    func skipTurn(choreId: UUID, reason: String?) async throws -> Chore
    
    /// Görev geçmişi kayıtlarını getirir
    func fetchLogs(for choreId: UUID?) async throws -> [ChoreLog]
}

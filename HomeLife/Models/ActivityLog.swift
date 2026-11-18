import Foundation

/// Analitik amaçlı kaydedilen kullanıcı aksiyon türleri
/// Ham değerler Firestore'da sorgulanabilir sabit anahtarlar olarak saklanır.
public enum ActivityActionType: String, Codable, CaseIterable, Identifiable {
    case guestAdded = "guest_added"
    case guestRemoved = "guest_removed"
    case choreCompleted = "chore_completed"
    /// İleride buzdolabı / alışveriş modülü için ayrılmıştır
    case fridgeItemAdded = "fridge_item_added"

    public var id: String { rawValue }
}

/// `houses/{houseId}/activity_logs` koleksiyonundaki tek bir aktivite kaydı
public struct ActivityLog: Identifiable, Codable, Equatable {
    public let id: UUID
    /// Aksiyonu gerçekleştiren Firebase kullanıcısının uid'si
    public let actorUserId: String
    public let actionType: ActivityActionType
    /// Aksiyonun hedef aldığı kaydın ID'si (misafir, görev vb.)
    public let targetId: String
    /// İstatistik çıkarmak için ek bilgiler (ör. hostRoommateId, choreTitle)
    public let metadata: [String: String]
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        actorUserId: String,
        actionType: ActivityActionType,
        targetId: String,
        metadata: [String: String] = [:],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.actorUserId = actorUserId
        self.actionType = actionType
        self.targetId = targetId
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

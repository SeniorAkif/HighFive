import Foundation

/// Ev işinin tamamlanma geçmiş kaydı
public struct ChoreLog: Identifiable, Codable, Equatable {
    public let id: UUID
    public let choreId: UUID
    public let choreTitle: String
    public let completedByRoommateId: UUID
    public let completedAt: Date
    public let notes: String?

    public init(
        id: UUID = UUID(),
        choreId: UUID,
        choreTitle: String,
        completedByRoommateId: UUID,
        completedAt: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.choreId = choreId
        self.choreTitle = choreTitle
        self.completedByRoommateId = completedByRoommateId
        self.completedAt = completedAt
        self.notes = notes
    }
}

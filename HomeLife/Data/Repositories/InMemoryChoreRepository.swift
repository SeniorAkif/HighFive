import Foundation

/// Bellek içi ev işleri ve döngü deposu
public final class InMemoryChoreRepository: ChoreRepositoryProtocol {
    private var chores: [Chore]
    private var logs: [ChoreLog]

    public init(
        initialChores: [Chore] = MockDataFactory.createChores(),
        initialLogs: [ChoreLog] = MockDataFactory.createInitialLogs()
    ) {
        self.chores = initialChores
        self.logs = initialLogs
    }

    public func fetchAll() async throws -> [Chore] {
        return chores
    }

    public func fetch(by id: UUID) async throws -> Chore? {
        return chores.first { $0.id == id }
    }

    public func add(_ chore: Chore) async throws {
        chores.append(chore)
    }

    public func update(_ chore: Chore) async throws {
        if let index = chores.firstIndex(where: { $0.id == chore.id }) {
            chores[index] = chore
        }
    }

    public func delete(id: UUID) async throws {
        chores.removeAll { $0.id == id }
        logs.removeAll { $0.choreId == id }
    }

    public func completeTurn(choreId: UUID, completedById: UUID, notes: String?) async throws -> Chore {
        guard let index = chores.firstIndex(where: { $0.id == choreId }) else {
            throw NSError(domain: "HighFive.ChoreRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Görev bulunamadı"])
        }

        var chore = chores[index]
        let now = Date()

        // 1. Yeni log kaydı oluştur
        let log = ChoreLog(
            choreId: chore.id,
            choreTitle: chore.title,
            completedByRoommateId: completedById,
            completedAt: now,
            notes: notes
        )
        logs.insert(log, at: 0)

        // 2. Sırayı bir sonraki kişiye devret (Round-Robin Rotasyonu)
        if !chore.rotationOrder.isEmpty {
            chore.currentAssigneeIndex = (chore.currentAssigneeIndex + 1) % chore.rotationOrder.count
        }

        // 3. Sonraki bitiş tarihini ve tamamlama bilgilerini güncelle
        chore.dueDate = chore.frequency.nextDueDate(from: now)
        chore.lastCompletedDate = now
        chore.lastCompletedById = completedById

        chores[index] = chore
        return chore
    }

    public func skipTurn(choreId: UUID, reason: String?) async throws -> Chore {
        guard let index = chores.firstIndex(where: { $0.id == choreId }) else {
            throw NSError(domain: "HighFive.ChoreRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Görev bulunamadı"])
        }

        var chore = chores[index]
        guard !chore.rotationOrder.isEmpty else { return chore }

        let skippedPersonId = chore.currentAssigneeId ?? chore.rotationOrder[0]

        // Sırayı bir sonraki kişiye atla
        chore.currentAssigneeIndex = (chore.currentAssigneeIndex + 1) % chore.rotationOrder.count

        // Log kaydı ekle
        let noteText = "Sıra atlandı. " + (reason ?? "Sebep belirtilmedi.")
        let log = ChoreLog(
            choreId: chore.id,
            choreTitle: chore.title,
            completedByRoommateId: skippedPersonId,
            completedAt: Date(),
            notes: noteText
        )
        logs.insert(log, at: 0)

        chores[index] = chore
        return chore
    }

    public func fetchLogs(for choreId: UUID?) async throws -> [ChoreLog] {
        if let choreId = choreId {
            return logs.filter { $0.choreId == choreId }
        }
        return logs
    }
}

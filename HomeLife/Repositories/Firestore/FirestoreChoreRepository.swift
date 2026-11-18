import Foundation
import FirebaseFirestore

/// Firestore tabanlı ev işleri ve döngü deposu
/// (`houses/{houseId}/chores` ve `houses/{houseId}/chore_logs`)
public final class FirestoreChoreRepository: ChoreRepositoryProtocol {
    private let db: Firestore
    private let session: HouseSessionManager
    private let analytics: any AnalyticsLoggerProtocol

    public init(db: Firestore, session: HouseSessionManager, analytics: any AnalyticsLoggerProtocol) {
        self.db = db
        self.session = session
        self.analytics = analytics
    }

    private func choresCollection() async throws -> CollectionReference {
        let context = try await session.currentContext()
        return FirestorePaths.houseCollection(FirestorePaths.chores, houseId: context.houseId, db: db)
    }

    private func logsCollection() async throws -> CollectionReference {
        let context = try await session.currentContext()
        return FirestorePaths.houseCollection(FirestorePaths.choreLogs, houseId: context.houseId, db: db)
    }

    // MARK: - CRUD

    public func fetchAll() async throws -> [Chore] {
        try await firebaseOperation("Chore.fetchAll") {
            let snapshot = try await choresCollection().getDocuments()
            return snapshot.decoded(as: Chore.self).sorted { $0.createdAt < $1.createdAt }
        }
    }

    public func fetch(by id: UUID) async throws -> Chore? {
        try await firebaseOperation("Chore.fetch(\(id.uuidString))") {
            let snapshot = try await choresCollection().document(id.uuidString).getDocument()
            guard snapshot.exists else { return nil }
            return try snapshot.data(as: Chore.self)
        }
    }

    public func add(_ chore: Chore) async throws {
        try await firebaseOperation("Chore.add(\(chore.title))") {
            try await choresCollection().document(chore.id.uuidString).setEncodable(chore)
        }
        FirebaseErrorLog.info("Görev eklendi: \(chore.title) (\(chore.id.uuidString))")
    }

    public func update(_ chore: Chore) async throws {
        try await firebaseOperation("Chore.update(\(chore.id.uuidString))") {
            try await choresCollection().document(chore.id.uuidString).setEncodable(chore)
        }
    }

    public func delete(id: UUID) async throws {
        try await firebaseOperation("Chore.delete(\(id.uuidString))") {
            try await deleteChoreAndLogs(id: id)
        }
    }

    private func deleteChoreAndLogs(id: UUID) async throws {
        let choreRef = try await choresCollection().document(id.uuidString)
        let logsSnapshot = try await logsCollection()
            .whereField("choreId", isEqualTo: id.uuidString)
            .getDocuments()

        let batch = db.batch()
        batch.deleteDocument(choreRef)
        for document in logsSnapshot.documents {
            batch.deleteDocument(document.reference)
        }
        try await batch.commit()
    }

    // MARK: - Döngü İşlemleri

    public func completeTurn(choreId: UUID, completedById: UUID, notes: String?) async throws -> Chore {
        var chore = try await requireChore(choreId)
        let wasOverdue = chore.isOverdue
        let now = Date()

        // 1. Yeni log kaydı oluştur
        let log = ChoreLog(
            choreId: chore.id,
            choreTitle: chore.title,
            completedByRoommateId: completedById,
            completedAt: now,
            notes: notes
        )

        // 2. Eğer sıralı döngü ise sırayı bir sonraki kişiye devret (Sabit sorumlu ise kişi değişmez)
        if chore.assignmentType == .rotating && !chore.rotationOrder.isEmpty {
            chore.currentAssigneeIndex = (chore.currentAssigneeIndex + 1) % chore.rotationOrder.count
        }

        // 3. Sonraki bitiş tarihini ve tamamlama bilgilerini güncelle
        chore.dueDate = chore.frequency.nextDueDate(from: now)
        chore.lastCompletedDate = now
        chore.lastCompletedById = completedById

        try await commit(chore: chore, log: log)

        analytics.log(.choreCompleted, targetId: chore.id.uuidString, metadata: [
            "choreTitle": chore.title,
            "category": chore.category.rawValue,
            "assignmentType": chore.assignmentType.rawValue,
            "frequency": chore.frequency.rawValue,
            "completedByRoommateId": completedById.uuidString,
            "wasOverdue": String(wasOverdue),
            "hasNotes": String(!(notes ?? "").isEmpty)
        ])

        return chore
    }

    public func skipTurn(choreId: UUID, reason: String?) async throws -> Chore {
        var chore = try await requireChore(choreId)
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

        try await commit(chore: chore, log: log)
        return chore
    }

    public func reassign(choreId: UUID, to roommateId: UUID) async throws -> Chore {
        var chore = try await requireChore(choreId)

        if chore.assignmentType == .dedicated {
            chore.dedicatedAssigneeId = roommateId
        } else {
            // Sıralı döngüde de mevcut sırayı seçilen kişiye ayarla
            if let orderIdx = chore.rotationOrder.firstIndex(of: roommateId) {
                chore.currentAssigneeIndex = orderIdx
            } else {
                chore.rotationOrder.append(roommateId)
                chore.currentAssigneeIndex = chore.rotationOrder.count - 1
            }
        }

        let log = ChoreLog(
            choreId: chore.id,
            choreTitle: chore.title,
            completedByRoommateId: roommateId,
            completedAt: Date(),
            notes: "Görev sorumlusu güncellendi."
        )

        try await commit(chore: chore, log: log)
        return chore
    }

    public func fetchLogs(for choreId: UUID?) async throws -> [ChoreLog] {
        try await firebaseOperation("Chore.fetchLogs") {
            try await queryLogs(for: choreId)
        }
    }

    private func queryLogs(for choreId: UUID?) async throws -> [ChoreLog] {
        var query: Query = try await logsCollection()
        if let choreId = choreId {
            query = query.whereField("choreId", isEqualTo: choreId.uuidString)
        }
        // Bileşik index gerektirmemek için sıralama istemcide yapılır
        let snapshot = try await query.getDocuments()
        return snapshot.decoded(as: ChoreLog.self).sorted { $0.completedAt > $1.completedAt }
    }

    // MARK: - Private

    private func requireChore(_ choreId: UUID) async throws -> Chore {
        guard let chore = try await fetch(by: choreId) else {
            throw NSError(domain: "HighFive.ChoreRepository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Görev bulunamadı"])
        }
        return chore
    }

    /// Görev güncellemesini ve log kaydını tek bir atomik batch ile yazar
    private func commit(chore: Chore, log: ChoreLog) async throws {
        try await firebaseOperation("Chore.commit(\(chore.id.uuidString))") {
            try await writeBatch(chore: chore, log: log)
        }
    }

    private func writeBatch(chore: Chore, log: ChoreLog) async throws {
        let encoder = Firestore.Encoder()
        let choreRef = try await choresCollection().document(chore.id.uuidString)
        let logRef = try await logsCollection().document(log.id.uuidString)

        let batch = db.batch()
        batch.setData(try encoder.encode(chore), forDocument: choreRef)
        batch.setData(try encoder.encode(log), forDocument: logRef)
        try await batch.commit()
    }
}

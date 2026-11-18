import Foundation
import FirebaseFirestore

/// Firestore tabanlı ev arkadaşı deposu (`houses/{houseId}/roommates`)
public final class FirestoreRoommateRepository: RoommateRepositoryProtocol {
    private let db: Firestore
    private let session: HouseSessionManager

    public init(db: Firestore, session: HouseSessionManager) {
        self.db = db
        self.session = session
    }

    /// Aktif ev hazır olana kadar bekler (anonim giriş + ilk kurulum)
    private func collection() async throws -> CollectionReference {
        let context = try await session.currentContext()
        return FirestorePaths.houseCollection(FirestorePaths.roommates, houseId: context.houseId, db: db)
    }

    public func fetchAll() async throws -> [Roommate] {
        try await firebaseOperation("Roommate.fetchAll") {
            let snapshot = try await collection().getDocuments()
            return snapshot.decoded(as: Roommate.self).sorted { $0.joinedAt < $1.joinedAt }
        }
    }

    public func fetch(by id: UUID) async throws -> Roommate? {
        try await firebaseOperation("Roommate.fetch(\(id.uuidString))") {
            let snapshot = try await collection().document(id.uuidString).getDocument()
            guard snapshot.exists else { return nil }
            return try snapshot.data(as: Roommate.self)
        }
    }

    public func add(_ roommate: Roommate) async throws {
        try await firebaseOperation("Roommate.add(\(roommate.name))") {
            try await collection().document(roommate.id.uuidString).setEncodable(roommate)
        }
    }

    public func update(_ roommate: Roommate) async throws {
        try await firebaseOperation("Roommate.update(\(roommate.id.uuidString))") {
            try await collection().document(roommate.id.uuidString).setEncodable(roommate)
        }
    }

    public func delete(id: UUID) async throws {
        try await firebaseOperation("Roommate.delete(\(id.uuidString))") {
            try await collection().document(id.uuidString).delete()
        }
    }
}

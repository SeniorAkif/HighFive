import Foundation
import FirebaseFirestore

/// Firestore tabanlı buzdolabı & kiler deposu (`houses/{houseId}/pantry_items`)
public final class FirestorePantryRepository: PantryRepositoryProtocol {
    private let db: Firestore
    private let session: HouseSessionManager
    private let analytics: any AnalyticsLoggerProtocol

    public init(db: Firestore, session: HouseSessionManager, analytics: any AnalyticsLoggerProtocol) {
        self.db = db
        self.session = session
        self.analytics = analytics
    }

    /// Aktif ev hazır olana kadar bekler (anonim giriş + ilk kurulum)
    private func collection() async throws -> CollectionReference {
        let context = try await session.currentContext()
        return FirestorePaths.houseCollection(FirestorePaths.pantryItems, houseId: context.houseId, db: db)
    }

    public func fetchAll() async throws -> [PantryItem] {
        try await firebaseOperation("Pantry.fetchAll") {
            let snapshot = try await collection().getDocuments()
            return snapshot.decoded(as: PantryItem.self)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }

    public func fetch(by id: UUID) async throws -> PantryItem? {
        try await firebaseOperation("Pantry.fetch(\(id.uuidString))") {
            let snapshot = try await collection().document(id.uuidString).getDocument()
            guard snapshot.exists else { return nil }
            return try snapshot.data(as: PantryItem.self)
        }
    }

    public func add(_ item: PantryItem) async throws {
        try await firebaseOperation("Pantry.add(\(item.name))") {
            try await collection().document(item.id.uuidString).setEncodable(item)
        }
        FirebaseErrorLog.info("Ürün eklendi: \(item.name) (\(item.id.uuidString))")
        analytics.log(.fridgeItemAdded, targetId: item.id.uuidString, metadata: Self.metadata(for: item))
    }

    public func update(_ item: PantryItem) async throws {
        try await firebaseOperation("Pantry.update(\(item.id.uuidString))") {
            try await collection().document(item.id.uuidString).setEncodable(item)
        }
    }

    public func delete(id: UUID) async throws {
        try await firebaseOperation("Pantry.delete(\(id.uuidString))") {
            try await collection().document(id.uuidString).delete()
        }
    }

    private static func metadata(for item: PantryItem) -> [String: String] {
        var metadata: [String: String] = [
            "name": item.name,
            "quantity": String(item.quantity),
            "unit": item.unit.rawValue,
            "category": item.category.rawValue,
            "location": item.location.rawValue
        ]
        if let expirationDate = item.expirationDate {
            metadata["expirationDate"] = expirationDate.analyticsString
        }
        if let addedBy = item.addedByRoommateId {
            metadata["addedByRoommateId"] = addedBy.uuidString
        }
        return metadata
    }
}

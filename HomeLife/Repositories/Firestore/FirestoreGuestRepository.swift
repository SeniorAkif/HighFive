import Foundation
import FirebaseFirestore

/// Firestore tabanlı misafir takvimi deposu (`houses/{houseId}/guest_visits`)
public final class FirestoreGuestRepository: GuestRepositoryProtocol {
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
        return FirestorePaths.houseCollection(FirestorePaths.guestVisits, houseId: context.houseId, db: db)
    }

    public func fetchAll() async throws -> [GuestVisit] {
        try await firebaseOperation("Guest.fetchAll") {
            let snapshot = try await collection().getDocuments()
            return snapshot.decoded(as: GuestVisit.self).sorted { $0.startDate < $1.startDate }
        }
    }

    public func fetch(by id: UUID) async throws -> GuestVisit? {
        try await firebaseOperation("Guest.fetch(\(id.uuidString))") {
            let snapshot = try await collection().document(id.uuidString).getDocument()
            guard snapshot.exists else { return nil }
            return try snapshot.data(as: GuestVisit.self)
        }
    }

    public func add(_ visit: GuestVisit) async throws {
        try await firebaseOperation("Guest.add(\(visit.guestName))") {
            try await collection().document(visit.id.uuidString).setEncodable(visit)
        }
        FirebaseErrorLog.info("Misafir eklendi: \(visit.guestName) (\(visit.id.uuidString))")
        analytics.log(.guestAdded, targetId: visit.id.uuidString, metadata: Self.metadata(for: visit))
    }

    public func update(_ visit: GuestVisit) async throws {
        try await firebaseOperation("Guest.update(\(visit.id.uuidString))") {
            try await collection().document(visit.id.uuidString).setEncodable(visit)
        }
    }

    public func delete(id: UUID) async throws {
        let existing: GuestVisit? = try await firebaseOperation("Guest.delete(\(id.uuidString))") {
            let ref = try await collection().document(id.uuidString)
            // Silinen misafirin bilgilerini analitik için önceden oku
            let existing = try? await ref.getDocument().data(as: GuestVisit.self)
            try await ref.delete()
            return existing
        }

        var metadata = existing.map(Self.metadata(for:)) ?? [:]
        metadata["removedAt"] = Date().analyticsString
        analytics.log(.guestRemoved, targetId: id.uuidString, metadata: metadata)
    }

    public func fetchVisits(from startDate: Date, to endDate: Date) async throws -> [GuestVisit] {
        try await firebaseOperation("Guest.fetchVisits") {
            // Tek alanda aralık sorgusu (ek index gerektirmez), bitiş koşulu istemcide süzülür
            let snapshot = try await collection()
                .whereField("startDate", isLessThanOrEqualTo: Timestamp(date: endDate))
                .getDocuments()
            return snapshot.decoded(as: GuestVisit.self)
                .filter { $0.endDate >= startDate }
                .sorted { $0.startDate < $1.startDate }
        }
    }

    private static func metadata(for visit: GuestVisit) -> [String: String] {
        [
            "hostRoommateId": visit.hostRoommateId.uuidString,
            "guestName": visit.guestName,
            "guestCount": String(visit.guestCount),
            "startDate": visit.startDate.analyticsString,
            "endDate": visit.endDate.analyticsString,
            "durationInDays": String(visit.durationInDays),
            "isOvernight": String(visit.isOvernight),
            "status": visit.status.rawValue
        ]
    }
}

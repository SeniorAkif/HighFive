import Foundation
import FirebaseFirestore

/// Oturum açmış kullanıcının aktif ev bilgisi
public struct HouseContext: Equatable {
    public let userId: String
    public let houseId: String
    public let mode: HouseMode
    /// İlk kurulumda kullanıcı adına oluşturulan ev arkadaşı kaydı
    public let ownerRoommateId: UUID?
}

/// Yeni bir ev oluşturulurken uygulanacak ilk kurulum stratejisi
public enum HouseSeedStrategy {
    /// Sadece kullanıcının kendisini temsil eden tek bir ev arkadaşı oluşturur
    case clean
    /// `MockDataFactory` örnek verileriyle (ev arkadaşları, görevler, misafirler) doldurur
    case sampleData
}

/// Anonim girişi bekleyip kullanıcının aktif evini (`houses/{houseId}`) çözen,
/// yoksa ilk kurulumu yapan oturum yöneticisi.
/// Firestore repository'leri tüm okuma/yazmalardan önce `currentContext()` ile bu bilgiyi bekler.
public actor HouseSessionManager {
    private let authManager: AuthManager
    private let db: Firestore
    private let seedStrategy: HouseSeedStrategy

    private var cachedContext: HouseContext?
    private var resolveTask: Task<HouseContext, Error>?

    public init(authManager: AuthManager, db: Firestore, seedStrategy: HouseSeedStrategy = .clean) {
        self.authManager = authManager
        self.db = db
        self.seedStrategy = seedStrategy
    }

    /// Aktif ev bilgisini döner; gerekirse giriş yapar ve evi oluşturur
    public func currentContext() async throws -> HouseContext {
        if let cachedContext {
            return cachedContext
        }
        if let resolveTask {
            return try await resolveTask.value
        }

        let task = Task { try await self.resolveContext() }
        resolveTask = task
        do {
            let context = try await task.value
            cachedContext = context
            resolveTask = nil
            FirebaseErrorLog.info("Aktif ev hazır — houseId: \(context.houseId), mode: \(context.mode.rawValue), uid: \(context.userId)")
            return context
        } catch {
            // Önbelleğe alınmaz; bir sonraki çağrı girişi/kurulumu yeniden dener
            resolveTask = nil
            FirebaseErrorLog.report("HouseSession.resolve", error)
            throw error
        }
    }

    /// Önbelleği temizleyip oturumu ve aktif evi yeniden çözer
    public func reload() async throws -> HouseContext {
        cachedContext = nil
        return try await currentContext()
    }

    /// Ev modunu Firestore'da günceller
    public func updateMode(_ mode: HouseMode) async throws -> HouseContext {
        let context = try await currentContext()
        try await FirestorePaths.house(context.houseId, db: db).updateData([
            "mode": mode.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        let updated = HouseContext(
            userId: context.userId,
            houseId: context.houseId,
            mode: mode,
            ownerRoommateId: context.ownerRoommateId
        )
        cachedContext = updated
        return updated
    }

    // MARK: - Private

    private func resolveContext() async throws -> HouseContext {
        let uid = try await authManager.signInIfNeeded()
        let userRef = FirestorePaths.user(uid, db: db)

        let userSnapshot = try await userRef.getDocument()
        if let houseId = userSnapshot.data()?["activeHouseId"] as? String {
            let houseSnapshot = try await FirestorePaths.house(houseId, db: db).getDocument()
            if houseSnapshot.exists, let data = houseSnapshot.data() {
                let mode = (data["mode"] as? String).flatMap(HouseMode.init(rawValue:)) ?? .personal
                let storedOwnerId = (data["ownerRoommateId"] as? String).flatMap(UUID.init(uuidString:))
                let ownerRoommateId = try await ensureOwnerRoommate(houseId: houseId, ownerRoommateId: storedOwnerId)
                return HouseContext(userId: uid, houseId: houseId, mode: mode, ownerRoommateId: ownerRoommateId)
            }
            print("⚠️ [Firebase] users/\(uid).activeHouseId (\(houseId)) bulunamadı, yeni ev oluşturuluyor")
        }

        return try await createInitialHouse(for: uid, userRef: userRef)
    }

    /// Mevcut evde varsayılan "Ben" ev arkadaşı kaydı yoksa oluşturur (eksik/yarım kurulumları onarır)
    private func ensureOwnerRoommate(houseId: String, ownerRoommateId: UUID?) async throws -> UUID {
        let houseRef = FirestorePaths.house(houseId, db: db)
        let roommates = houseRef.collection(FirestorePaths.roommates)

        if let ownerRoommateId {
            let snapshot = try await roommates.document(ownerRoommateId.uuidString).getDocument()
            if snapshot.exists { return ownerRoommateId }
        }

        let owner = Self.makeOwnerRoommate()
        let batch = db.batch()
        batch.setData(try Firestore.Encoder().encode(owner), forDocument: roommates.document(owner.id.uuidString))
        batch.updateData([
            "ownerRoommateId": owner.id.uuidString,
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: houseRef)
        try await batch.commit()
        print("⚠️ [Firebase] houses/\(houseId) için eksik \"\(owner.name)\" kaydı yeniden oluşturuldu")
        return owner.id
    }

    /// İlk açılışta kullanıcı için yeni bir ev oluşturur ve başlangıç verisini tek seferde yazar
    private func createInitialHouse(for uid: String, userRef: DocumentReference) async throws -> HouseContext {
        let houseRef = db.collection(FirestorePaths.houses).document()
        let houseId = houseRef.documentID
        let encoder = Firestore.Encoder()
        let batch = db.batch()

        let roommates: [Roommate]
        let chores: [Chore]
        let guestVisits: [GuestVisit]
        let choreLogs: [ChoreLog]
        let mode: HouseMode
        let ownerRoommateId: UUID

        switch seedStrategy {
        case .clean:
            let owner = Self.makeOwnerRoommate()
            roommates = [owner]
            chores = []
            guestVisits = []
            choreLogs = []
            mode = .personal
            ownerRoommateId = owner.id
        case .sampleData:
            roommates = MockDataFactory.createRoommates()
            chores = MockDataFactory.createChores()
            guestVisits = MockDataFactory.createGuestVisits()
            choreLogs = MockDataFactory.createInitialLogs()
            mode = .shared
            ownerRoommateId = MockDataFactory.roommateAhmetId
        }

        batch.setData([
            "name": Self.defaultHouseName(for: mode),
            "mode": mode.rawValue,
            "ownerId": uid,
            "memberIds": [uid],
            "ownerRoommateId": ownerRoommateId.uuidString,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ], forDocument: houseRef)

        for roommate in roommates {
            batch.setData(try encoder.encode(roommate), forDocument: houseRef.collection(FirestorePaths.roommates).document(roommate.id.uuidString))
        }
        for chore in chores {
            batch.setData(try encoder.encode(chore), forDocument: houseRef.collection(FirestorePaths.chores).document(chore.id.uuidString))
        }
        for visit in guestVisits {
            batch.setData(try encoder.encode(visit), forDocument: houseRef.collection(FirestorePaths.guestVisits).document(visit.id.uuidString))
        }
        for log in choreLogs {
            batch.setData(try encoder.encode(log), forDocument: houseRef.collection(FirestorePaths.choreLogs).document(log.id.uuidString))
        }

        batch.setData([
            "activeHouseId": houseId,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: userRef, merge: true)

        try await batch.commit()

        return HouseContext(userId: uid, houseId: houseId, mode: mode, ownerRoommateId: ownerRoommateId)
    }

    private static func makeOwnerRoommate() -> Roommate {
        let isTurkish = LanguageManager.shared.locale.identifier.starts(with: "tr")
        return Roommate(
            name: isTurkish ? "Ben" : "Me",
            avatarEmoji: "🙂",
            avatarColorHex: "#4F46E5"
        )
    }

    private static func defaultHouseName(for mode: HouseMode) -> String {
        let isTurkish = LanguageManager.shared.locale.identifier.starts(with: "tr")
        switch mode {
        case .personal: return isTurkish ? "Evim" : "My Home"
        case .shared: return isTurkish ? "Ortak Evimiz" : "Our Home"
        }
    }
}

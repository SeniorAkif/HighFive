import Foundation
import FirebaseFirestore

/// Firestore koleksiyon yolları
///
/// users/{uid}                              → { activeHouseId }
/// houses/{houseId}                         → { name, mode, ownerId, memberIds, ownerRoommateId }
/// houses/{houseId}/roommates/{id}
/// houses/{houseId}/chores/{id}
/// houses/{houseId}/chore_logs/{id}
/// houses/{houseId}/guest_visits/{id}
/// houses/{houseId}/activity_logs/{id}
/// houses/{houseId}/pantry_items/{id}
public enum FirestorePaths {
    public static let users = "users"
    public static let houses = "houses"
    public static let roommates = "roommates"
    public static let chores = "chores"
    public static let choreLogs = "chore_logs"
    public static let guestVisits = "guest_visits"
    public static let activityLogs = "activity_logs"
    public static let pantryItems = "pantry_items"

    public static func user(_ uid: String, db: Firestore) -> DocumentReference {
        db.collection(users).document(uid)
    }

    public static func house(_ houseId: String, db: Firestore) -> DocumentReference {
        db.collection(houses).document(houseId)
    }

    public static func houseCollection(_ name: String, houseId: String, db: Firestore) -> CollectionReference {
        house(houseId, db: db).collection(name)
    }
}

extension DocumentReference {
    /// Codable modeli Firestore'a yazar ve sunucu onayını bekler
    func setEncodable<T: Encodable>(_ value: T) async throws {
        let data = try Firestore.Encoder().encode(value)
        try await setData(data)
    }
}

extension QuerySnapshot {
    /// Dokümanları modele çevirir; bozuk/eski şemalı dokümanları atlar
    func decoded<T: Decodable>(as type: T.Type) -> [T] {
        documents.compactMap { document in
            do {
                return try document.data(as: type)
            } catch {
                FirebaseErrorLog.report("Decode \(T.self) (\(document.reference.path))", error)
                return nil
            }
        }
    }
}

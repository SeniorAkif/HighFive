import Foundation
import FirebaseFirestore

/// Arka planda sessizce aktivite kaydı tutan analitik servis protokolü
public protocol AnalyticsLoggerProtocol: AnyObject {
    /// Kaydı arka planda yazar; hata olsa bile çağıranı bloklamaz veya hata fırlatmaz
    func log(_ actionType: ActivityActionType, targetId: String, metadata: [String: String])
}

/// Önizleme ve testler için hiçbir şey yazmayan logger
public final class NoopAnalyticsLogger: AnalyticsLoggerProtocol {
    public init() {}

    public func log(_ actionType: ActivityActionType, targetId: String, metadata: [String: String]) {}
}

/// `houses/{houseId}/activity_logs` koleksiyonuna kayıt yazan Firestore logger
public final class AnalyticsLogger: AnalyticsLoggerProtocol {
    private let db: Firestore
    private let session: HouseSessionManager

    public init(db: Firestore, session: HouseSessionManager) {
        self.db = db
        self.session = session
    }

    public func log(_ actionType: ActivityActionType, targetId: String, metadata: [String: String] = [:]) {
        let db = self.db
        let session = self.session
        let timestamp = Date()

        Task.detached(priority: .background) {
            do {
                let context = try await session.currentContext()
                let entry = ActivityLog(
                    actorUserId: context.userId,
                    actionType: actionType,
                    targetId: targetId,
                    metadata: metadata,
                    timestamp: timestamp
                )
                var data = try Firestore.Encoder().encode(entry)
                // Cihaz saatinden bağımsız sıralama için sunucu zamanı da saklanır
                data["serverTimestamp"] = FieldValue.serverTimestamp()

                try await FirestorePaths
                    .houseCollection(FirestorePaths.activityLogs, houseId: context.houseId, db: db)
                    .document(entry.id.uuidString)
                    .setData(data)
            } catch {
                #if DEBUG
                print("[AnalyticsLogger] \(actionType.rawValue) kaydı yazılamadı: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

extension Date {
    /// Analitik metadata'sı için ISO 8601 metin
    var analyticsString: String {
        ISO8601DateFormatter().string(from: self)
    }
}

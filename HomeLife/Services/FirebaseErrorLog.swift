import Foundation

/// Firebase / Firestore hatalarını konsola okunaklı biçimde yazan yardımcı
public enum FirebaseErrorLog {
    public static func report(_ operation: String, _ error: Error) {
        let nsError = error as NSError
        print("🔥 [Firebase] \(operation) BAŞARISIZ — domain: \(nsError.domain), code: \(nsError.code), mesaj: \(nsError.localizedDescription)")
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
            print("   ↳ underlying — domain: \(underlying.domain), code: \(underlying.code), mesaj: \(underlying.localizedDescription)")
        }
    }

    public static func info(_ message: String) {
        print("✅ [Firebase] \(message)")
    }
}

/// Bir Firebase işlemini çalıştırır; hata olursa konsola yazar ve hatayı yeniden fırlatır
func firebaseOperation<T>(_ name: String, _ body: () async throws -> T) async throws -> T {
    do {
        return try await body()
    } catch {
        FirebaseErrorLog.report(name, error)
        throw error
    }
}

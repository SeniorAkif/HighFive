import Foundation
import FirebaseAuth

/// Firebase anonim kimlik doğrulamasını yöneten servis
@MainActor
public final class AuthManager: ObservableObject {
    /// Aktif Firebase kullanıcısının uid'si (giriş yapılmadıysa nil)
    @Published public private(set) var userId: String?
    @Published public private(set) var isSigningIn: Bool = false
    @Published public private(set) var errorMessage: String?

    private var signInTask: Task<String, Error>?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    public init() {
        self.userId = Auth.auth().currentUser?.uid
        self.authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            let uid = user?.uid
            Task { @MainActor in
                self?.userId = uid
            }
        }
    }

    /// Oturum yoksa anonim giriş yapar ve kullanıcının uid'sini döner.
    /// Aynı anda gelen çağrılar tek bir giriş isteğini paylaşır.
    @discardableResult
    public func signInIfNeeded() async throws -> String {
        if let uid = Auth.auth().currentUser?.uid {
            userId = uid
            return uid
        }
        if let signInTask {
            return try await signInTask.value
        }

        let task = Task<String, Error> {
            let result = try await Auth.auth().signInAnonymously()
            return result.user.uid
        }
        signInTask = task
        isSigningIn = true
        defer {
            isSigningIn = false
            signInTask = nil
        }

        do {
            let uid = try await task.value
            userId = uid
            errorMessage = nil
            FirebaseErrorLog.info("Anonim giriş başarılı, uid: \(uid)")
            return uid
        } catch {
            FirebaseErrorLog.report("Auth.signInAnonymously", error)
            errorMessage = error.localizedDescription
            throw error
        }
    }
}

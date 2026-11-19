import Foundation
import SwiftUI
import FirebaseFirestore

/// Uygulama çapında bağımlılıkları yöneten kapsayıcı (Dependency Injection)
@MainActor
public final class DependencyContainer: ObservableObject {
    public let roommateRepository: any RoommateRepositoryProtocol
    public let choreRepository: any ChoreRepositoryProtocol
    public let guestRepository: any GuestRepositoryProtocol
    public let pantryRepository: any PantryRepositoryProtocol
    public let analyticsLogger: any AnalyticsLoggerProtocol

    /// Canlı uygulamada Firebase oturumu; önizlemelerde nil
    public let authManager: AuthManager?
    private let houseSession: HouseSessionManager?

    /// Aktif evin kullanım modu
    @Published public private(set) var houseMode: HouseMode
    /// Firestore'daki aktif ev dokümanının ID'si (`houses/{houseId}`)
    @Published public private(set) var activeHouseId: String?
    /// Oturumdaki kullanıcıyı temsil eden varsayılan ("Ben") ev arkadaşı
    @Published public private(set) var currentRoommateId: UUID?
    @Published public private(set) var sessionErrorMessage: String?

    public init(
        roommateRepository: any RoommateRepositoryProtocol = InMemoryRoommateRepository(),
        choreRepository: any ChoreRepositoryProtocol = InMemoryChoreRepository(),
        guestRepository: any GuestRepositoryProtocol = InMemoryGuestRepository(),
        pantryRepository: any PantryRepositoryProtocol = InMemoryPantryRepository(),
        analyticsLogger: any AnalyticsLoggerProtocol = NoopAnalyticsLogger(),
        authManager: AuthManager? = nil,
        houseSession: HouseSessionManager? = nil,
        houseMode: HouseMode = .shared
    ) {
        self.roommateRepository = roommateRepository
        self.choreRepository = choreRepository
        self.guestRepository = guestRepository
        self.pantryRepository = pantryRepository
        self.analyticsLogger = analyticsLogger
        self.authManager = authManager
        self.houseSession = houseSession
        self.houseMode = houseMode
    }

    /// Canlı uygulama için Firestore repository'leriyle kurulmuş kapsayıcı.
    /// `FirebaseApp.configure()` çağrısından sonra oluşturulmalıdır.
    public static func live() -> DependencyContainer {
        let db = Firestore.firestore()
        let authManager = AuthManager()
        let session = HouseSessionManager(authManager: authManager, db: db)
        let analytics = AnalyticsLogger(db: db, session: session)

        return DependencyContainer(
            roommateRepository: FirestoreRoommateRepository(db: db, session: session),
            choreRepository: FirestoreChoreRepository(db: db, session: session, analytics: analytics),
            guestRepository: FirestoreGuestRepository(db: db, session: session, analytics: analytics),
            pantryRepository: FirestorePantryRepository(db: db, session: session, analytics: analytics),
            analyticsLogger: analytics,
            authManager: authManager,
            houseSession: session,
            houseMode: .personal
        )
    }

    /// Önizleme ve testler için hazır örnek
    public static var preview: DependencyContainer {
        DependencyContainer()
    }

    /// Anonim girişi yapar ve aktif evi (yoksa oluşturarak) yükler
    public func bootstrap() async {
        guard let houseSession else { return }
        do {
            let context = try await houseSession.currentContext()
            apply(context)
        } catch {
            sessionErrorMessage = error.localizedDescription
        }
    }

    /// Oturum hatasından sonra girişi ve ev kurulumunu yeniden dener
    public func retryBootstrap() async {
        guard let houseSession else { return }
        sessionErrorMessage = nil
        do {
            apply(try await houseSession.reload())
        } catch {
            sessionErrorMessage = error.localizedDescription
        }
    }

    public func clearSessionError() {
        sessionErrorMessage = nil
    }

    private func apply(_ context: HouseContext) {
        activeHouseId = context.houseId
        houseMode = context.mode
        currentRoommateId = context.ownerRoommateId
        sessionErrorMessage = nil
    }

    /// Ev modunu değiştirir (canlıda Firestore'a da yazılır)
    public func setHouseMode(_ mode: HouseMode) async {
        guard let houseSession else {
            houseMode = mode
            return
        }
        do {
            apply(try await houseSession.updateMode(mode))
        } catch {
            sessionErrorMessage = error.localizedDescription
        }
    }
}

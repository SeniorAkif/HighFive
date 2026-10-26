import Foundation
import SwiftUI

/// Uygulama çapında bağımlılıkları yöneten kapsayıcı (Dependency Injection)
@MainActor
public final class DependencyContainer: ObservableObject {
    public let roommateRepository: any RoommateRepositoryProtocol
    public let choreRepository: any ChoreRepositoryProtocol
    public let guestRepository: any GuestRepositoryProtocol

    public init(
        roommateRepository: any RoommateRepositoryProtocol = InMemoryRoommateRepository(),
        choreRepository: any ChoreRepositoryProtocol = InMemoryChoreRepository(),
        guestRepository: any GuestRepositoryProtocol = InMemoryGuestRepository()
    ) {
        self.roommateRepository = roommateRepository
        self.choreRepository = choreRepository
        self.guestRepository = guestRepository
    }

    /// Önizleme ve testler için hazır örnek
    public static var preview: DependencyContainer {
        DependencyContainer()
    }
}

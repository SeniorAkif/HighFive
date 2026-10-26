import Foundation
import SwiftUI

@MainActor
public final class HouseholdViewModel: ObservableObject {
    @Published public var roommates: [Roommate] = []
    @Published public var chores: [Chore] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var isShowingAddSheet: Bool = false

    private let roommateRepository: any RoommateRepositoryProtocol
    private let choreRepository: any ChoreRepositoryProtocol

    public init(
        roommateRepository: any RoommateRepositoryProtocol,
        choreRepository: any ChoreRepositoryProtocol
    ) {
        self.roommateRepository = roommateRepository
        self.choreRepository = choreRepository
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedRoommates = roommateRepository.fetchAll()
            async let fetchedChores = choreRepository.fetchAll()

            let (r, c) = try await (fetchedRoommates, fetchedChores)
            self.roommates = r
            self.chores = c
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Bir ev arkadaşına atanmış toplam görev sayısı
    public func activeChoreCount(for roommateId: UUID) -> Int {
        chores.filter { $0.rotationOrder.contains(roommateId) }.count
    }

    /// Bir ev arkadaşının şu anda sırası gelen görev sayısı
    public func currentTurnChoreCount(for roommateId: UUID) -> Int {
        chores.filter { $0.currentAssigneeId == roommateId }.count
    }

    /// Yeni ev arkadaşı ekler
    public func addRoommate(
        name: String,
        nickname: String?,
        avatarEmoji: String,
        colorHex: String,
        phoneNumber: String?,
        roomName: String?
    ) async {
        let newRoommate = Roommate(
            name: name,
            nickname: nickname,
            avatarEmoji: avatarEmoji,
            avatarColorHex: colorHex,
            phoneNumber: phoneNumber,
            roomName: roomName
        )
        do {
            try await roommateRepository.add(newRoommate)
            await loadData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    /// Ev arkadaşını siler
    public func deleteRoommate(_ roommate: Roommate) async {
        do {
            try await roommateRepository.delete(id: roommate.id)
            roommates.removeAll { $0.id == roommate.id }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

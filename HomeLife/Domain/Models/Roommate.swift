import Foundation

/// Öğrenci evindeki bir ev arkadaşını temsil eden model
public struct Roommate: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var nickname: String?
    public var avatarEmoji: String
    public var avatarColorHex: String
    public var phoneNumber: String?
    public var roomName: String?
    public var isActive: Bool
    public var joinedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        nickname: String? = nil,
        avatarEmoji: String = "👤",
        avatarColorHex: String = "#4F46E5",
        phoneNumber: String? = nil,
        roomName: String? = nil,
        isActive: Bool = true,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.avatarEmoji = avatarEmoji
        self.avatarColorHex = avatarColorHex
        self.phoneNumber = phoneNumber
        self.roomName = roomName
        self.isActive = isActive
        self.joinedAt = joinedAt
    }

    /// Kullanıcı için görünen ad (varsa takma ad, yoksa isim)
    public var displayName: String {
        if let nickname = nickname, !nickname.isEmpty {
            return nickname
        }
        return name
    }

    /// İsim baş harfleri (avatar için)
    public var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            let first = parts[0].prefix(1)
            let second = parts[1].prefix(1)
            return "\(first)\(second)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

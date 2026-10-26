import Foundation
import SwiftUI

/// Misafirlik durumu
public enum GuestVisitStatus: String, Codable, CaseIterable, Identifiable {
    case upcoming = "Yaklaşan"
    case active = "Şu An Evde"
    case completed = "Ayrıldı"
    case cancelled = "İptal Edildi"

    public var id: String { rawValue }

    public var badgeColorHex: String {
        switch self {
        case .upcoming: return "#3B82F6"   // Blue
        case .active: return "#10B981"     // Emerald
        case .completed: return "#6B7280"  // Gray
        case .cancelled: return "#EF4444"  // Red
        }
    }
}

/// Eve gelecek misafiri temsil eden model
public struct GuestVisit: Identifiable, Codable, Equatable {
    public let id: UUID
    /// Misafiri davet eden ev arkadaşının ID'si
    public var hostRoommateId: UUID
    public var guestName: String
    public var guestCount: Int
    public var startDate: Date
    public var endDate: Date
    public var isOvernight: Bool
    public var stayLocation: String
    public var notes: String
    public var status: GuestVisitStatus
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        hostRoommateId: UUID,
        guestName: String,
        guestCount: Int = 1,
        startDate: Date = Date(),
        endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
        isOvernight: Bool = true,
        stayLocation: String = "Misafir / Salon",
        notes: String = "",
        status: GuestVisitStatus = .upcoming,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.hostRoommateId = hostRoommateId
        self.guestName = guestName
        self.guestCount = guestCount
        self.startDate = startDate
        self.endDate = endDate
        self.isOvernight = isOvernight
        self.stayLocation = stayLocation
        self.notes = notes
        self.status = status
        self.createdAt = createdAt
    }

    /// Ziyaret şu an aktif mi? (Şu anki tarih aralığında mı?)
    public var isCurrentlyActive: Bool {
        let now = Date()
        return startDate <= now && now <= endDate && status != .cancelled
    }

    /// Kaç gün sürecek?
    public var durationInDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(1, components.day ?? 1)
    }

    /// Başka bir misafir ziyareti ile tarih çakışması var mı?
    public func overlaps(with other: GuestVisit) -> Bool {
        guard self.id != other.id, self.status != .cancelled, other.status != .cancelled else { return false }
        return self.startDate < other.endDate && self.endDate > other.startDate
    }
}

import Foundation
import SwiftUI

/// Ev işi kategorileri
public enum ChoreCategory: String, Codable, CaseIterable, Identifiable {
    case kitchen = "Mutfak"
    case trash = "Çöp"
    case bathroom = "Banyo & WC"
    case livingRoom = "Salon"
    case shopping = "Alışveriş"
    case general = "Genel Temizlik"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .kitchen: return "fork.knife"
        case .trash: return "trash.fill"
        case .bathroom: return "shower.fill"
        case .livingRoom: return "sofa.fill"
        case .shopping: return "cart.fill"
        case .general: return "sparkles"
        }
    }

    public var colorHex: String {
        switch self {
        case .kitchen: return "#F59E0B"     // Amber
        case .trash: return "#EF4444"       // Red
        case .bathroom: return "#06B6D4"    // Cyan
        case .livingRoom: return "#8B5CF6"  // Purple
        case .shopping: return "#10B981"    // Emerald
        case .general: return "#3B82F6"     // Blue
        }
    }
}

/// Görevin tekrarlanma sıklığı
public enum ChoreFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "Her Gün"
    case everyOtherDay = "2 Günde Bir"
    case weekly = "Haftada 1"
    case biweekly = "2 Haftada 1"
    case monthly = "Ayda 1"
    case asNeeded = "İhtiyaç Oldukça"

    public var id: String { rawValue }

    /// Görev tamamlandığında bir sonraki bitiş tarihini hesaplar
    public func nextDueDate(from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .everyOtherDay:
            return calendar.date(byAdding: .day, value: 2, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .day, value: 7, to: date) ?? date
        case .biweekly:
            return calendar.date(byAdding: .day, value: 14, to: date) ?? date
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
        case .asNeeded:
            return calendar.date(byAdding: .day, value: 3, to: date) ?? date
        }
    }
}

/// Görevin atanma ve paylaşılma türü
public enum ChoreAssignmentType: String, Codable, CaseIterable, Identifiable {
    case rotating = "Sıralı Döngü"       // Ev arkadaşları sırayla tur usulü yapar
    case dedicated = "Sabit Sorumlu"     // Belirli bir arkadaşın daimi görevidir (örn: Mutfak temizliği)

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .rotating: return "arrow.triangle.2.circlepath"
        case .dedicated: return "pin.fill"
        }
    }
}

/// Sıralı veya sabit paylaşımlı ev işi modeli
public struct Chore: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var description: String
    public var category: ChoreCategory
    public var assignmentType: ChoreAssignmentType
    /// Sabit sorumlu atandıysa sorumlu kişinin UUID'si
    public var dedicatedAssigneeId: UUID?
    /// Görevi sırayla yapacak kişilerin ID listesi (sıralı döngü)
    public var rotationOrder: [UUID]
    /// Şu anki sıradaki kişinin index'i (rotationOrder[currentAssigneeIndex])
    public var currentAssigneeIndex: Int
    public var frequency: ChoreFrequency
    public var dueDate: Date
    public var lastCompletedDate: Date?
    public var lastCompletedById: UUID?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        category: ChoreCategory = .general,
        assignmentType: ChoreAssignmentType = .rotating,
        dedicatedAssigneeId: UUID? = nil,
        rotationOrder: [UUID] = [],
        currentAssigneeIndex: Int = 0,
        frequency: ChoreFrequency = .weekly,
        dueDate: Date = Date(),
        lastCompletedDate: Date? = nil,
        lastCompletedById: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.assignmentType = assignmentType
        self.dedicatedAssigneeId = dedicatedAssigneeId
        self.rotationOrder = rotationOrder
        self.currentAssigneeIndex = currentAssigneeIndex
        self.frequency = frequency
        self.dueDate = dueDate
        self.lastCompletedDate = lastCompletedDate
        self.lastCompletedById = lastCompletedById
        self.createdAt = createdAt
    }

    /// Sıradaki veya sorumlu kişinin UUID'si
    public var currentAssigneeId: UUID? {
        switch assignmentType {
        case .rotating:
            guard !rotationOrder.isEmpty else { return nil }
            let validIndex = currentAssigneeIndex % rotationOrder.count
            return rotationOrder[validIndex]
        case .dedicated:
            return dedicatedAssigneeId ?? rotationOrder.first
        }
    }

    /// Son teslim tarihi geçmiş mi?
    public var isOverdue: Bool {
        return dueDate < Calendar.current.startOfDay(for: Date())
    }

    /// Bugün mü yapılması gerekiyor?
    public var isDueToday: Bool {
        Calendar.current.isDateInToday(dueDate)
    }

    /// Kalan gün sayısı (negatif ise gecikmiş gün sayısı)
    public var daysUntilDue: Int {
        let calendar = Calendar.current
        let start1 = calendar.startOfDay(for: Date())
        let start2 = calendar.startOfDay(for: dueDate)
        let components = calendar.dateComponents([.day], from: start1, to: start2)
        return components.day ?? 0
    }
}

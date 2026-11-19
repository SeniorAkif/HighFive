import Foundation

/// Ürünün evde saklandığı yer
public enum PantryStorageLocation: String, Codable, CaseIterable, Identifiable {
    case fridge
    case freezer
    case pantry

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .fridge: return "refrigerator.fill"
        case .freezer: return "snowflake"
        case .pantry: return "cabinet.fill"
        }
    }

    public var localizedTitle: String {
        let isTurkish = LanguageManager.shared.locale.identifier.starts(with: "tr")
        switch self {
        case .fridge: return isTurkish ? "Buzdolabı" : "Fridge"
        case .freezer: return isTurkish ? "Dondurucu" : "Freezer"
        case .pantry: return isTurkish ? "Kiler" : "Pantry"
        }
    }
}

/// Ürün kategorisi
public enum PantryCategory: String, Codable, CaseIterable, Identifiable {
    case dairy
    case produce
    case meat
    case staples
    case beverages
    case snacks
    case frozen
    case condiments
    case other

    public var id: String { rawValue }

    public var emoji: String {
        switch self {
        case .dairy: return "🧀"
        case .produce: return "🥦"
        case .meat: return "🍗"
        case .staples: return "🍝"
        case .beverages: return "🥤"
        case .snacks: return "🍪"
        case .frozen: return "🧊"
        case .condiments: return "🧂"
        case .other: return "🛒"
        }
    }

    public var colorHex: String {
        switch self {
        case .dairy: return "#3B82F6"      // Blue
        case .produce: return "#10B981"    // Emerald
        case .meat: return "#EF4444"       // Red
        case .staples: return "#F59E0B"    // Amber
        case .beverages: return "#06B6D4"  // Cyan
        case .snacks: return "#EC4899"     // Pink
        case .frozen: return "#6366F1"     // Indigo
        case .condiments: return "#8B5CF6" // Violet
        case .other: return "#6B7280"      // Gray
        }
    }

    /// Yeni ürün eklerken bu kategori için önerilen saklama yeri
    public var suggestedLocation: PantryStorageLocation {
        switch self {
        case .dairy, .produce, .meat: return .fridge
        case .frozen: return .freezer
        case .staples, .beverages, .snacks, .condiments, .other: return .pantry
        }
    }

    public var localizedTitle: String {
        let isTurkish = LanguageManager.shared.locale.identifier.starts(with: "tr")
        switch self {
        case .dairy: return isTurkish ? "Süt Ürünleri" : "Dairy"
        case .produce: return isTurkish ? "Sebze & Meyve" : "Produce"
        case .meat: return isTurkish ? "Et & Tavuk" : "Meat & Poultry"
        case .staples: return isTurkish ? "Temel Gıda" : "Staples"
        case .beverages: return isTurkish ? "İçecek" : "Beverages"
        case .snacks: return isTurkish ? "Atıştırmalık" : "Snacks"
        case .frozen: return isTurkish ? "Donuk Gıda" : "Frozen"
        case .condiments: return isTurkish ? "Sos & Baharat" : "Condiments"
        case .other: return isTurkish ? "Diğer" : "Other"
        }
    }
}

/// Miktar birimi
public enum PantryUnit: String, Codable, CaseIterable, Identifiable {
    case piece
    case pack
    case bottle
    case liter
    case milliliter
    case kilogram
    case gram

    public var id: String { rawValue }

    /// Listedeki +/- butonlarının tek dokunuşta değiştirdiği miktar
    public var quickStep: Double {
        switch self {
        case .piece, .pack, .bottle: return 1
        case .liter, .kilogram: return 0.5
        case .milliliter, .gram: return 100
        }
    }

    /// Ekleme ekranındaki Stepper için izin verilen en büyük değer
    public var maxQuantity: Double {
        switch self {
        case .milliliter, .gram: return 10_000
        default: return 100
        }
    }

    public var localizedShortTitle: String {
        let isTurkish = LanguageManager.shared.locale.identifier.starts(with: "tr")
        switch self {
        case .piece: return isTurkish ? "adet" : "pcs"
        case .pack: return isTurkish ? "paket" : "pack"
        case .bottle: return isTurkish ? "şişe" : "bottle"
        case .liter: return isTurkish ? "L" : "L"
        case .milliliter: return "ml"
        case .kilogram: return "kg"
        case .gram: return isTurkish ? "gr" : "g"
        }
    }

    public var localizedTitle: String {
        let isTurkish = LanguageManager.shared.locale.identifier.starts(with: "tr")
        switch self {
        case .piece: return isTurkish ? "Adet" : "Piece"
        case .pack: return isTurkish ? "Paket" : "Pack"
        case .bottle: return isTurkish ? "Şişe" : "Bottle"
        case .liter: return isTurkish ? "Litre" : "Liter"
        case .milliliter: return isTurkish ? "Mililitre" : "Milliliter"
        case .kilogram: return isTurkish ? "Kilogram" : "Kilogram"
        case .gram: return isTurkish ? "Gram" : "Gram"
        }
    }
}

/// Son kullanma tarihine göre ürün durumu
public enum PantryExpiryStatus: Int, Comparable {
    case expired = 0
    case expiresToday = 1
    case expiringSoon = 2
    case fresh = 3
    case noDate = 4

    /// Bu kadar gün (veya daha az) kalan ürünler "yaklaşıyor" sayılır
    public static let soonThresholdDays = 3

    public static func < (lhs: PantryExpiryStatus, rhs: PantryExpiryStatus) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Listede öne çıkarılması gereken bir durum mu?
    public var needsAttention: Bool {
        self == .expired || self == .expiresToday || self == .expiringSoon
    }

    public var colorHex: String? {
        switch self {
        case .expired: return "#EF4444"                        // Red
        case .expiresToday, .expiringSoon: return "#F59E0B"    // Amber
        case .fresh, .noDate: return nil
        }
    }
}

/// Buzdolabı / kilerdeki tek bir ürünü temsil eden model (`houses/{houseId}/pantry_items/{id}`)
public struct PantryItem: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var quantity: Double
    public var unit: PantryUnit
    public var category: PantryCategory
    public var location: PantryStorageLocation
    /// Opsiyonel son kullanma tarihi (SKT)
    public var expirationDate: Date?
    /// Ürünü ekleyen ev arkadaşı (ortak ev modunda gösterilir)
    public var addedByRoommateId: UUID?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        quantity: Double = 1,
        unit: PantryUnit = .piece,
        category: PantryCategory = .other,
        location: PantryStorageLocation = .fridge,
        expirationDate: Date? = nil,
        addedByRoommateId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.category = category
        self.location = location
        self.expirationDate = expirationDate
        self.addedByRoommateId = addedByRoommateId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Ürün tükendi mi?
    public var isDepleted: Bool {
        quantity <= 0
    }

    /// SKT'ye kalan gün sayısı (bugün = 0, geçmiş = negatif)
    public func daysUntilExpiration(from now: Date = Date()) -> Int? {
        guard let expirationDate else { return nil }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: now)
        let end = calendar.startOfDay(for: expirationDate)
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    public func expiryStatus(from now: Date = Date()) -> PantryExpiryStatus {
        guard let days = daysUntilExpiration(from: now) else { return .noDate }
        if days < 0 { return .expired }
        if days == 0 { return .expiresToday }
        if days <= PantryExpiryStatus.soonThresholdDays { return .expiringSoon }
        return .fresh
    }

    /// "2", "1,5", "250" gibi okunaklı miktar metni
    public var formattedQuantity: String {
        let formatter = NumberFormatter()
        formatter.locale = LanguageManager.shared.locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: quantity)) ?? "\(quantity)"
    }

    /// "2 adet", "1,5 L"
    public var quantityWithUnitText: String {
        "\(formattedQuantity) \(unit.localizedShortTitle)"
    }
}

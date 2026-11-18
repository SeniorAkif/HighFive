import Foundation

/// Evin kullanım modu (Kişisel / Ortak Ev)
public enum HouseMode: String, Codable, CaseIterable, Identifiable {
    /// Tek kişilik ev: görevler ve misafirler yalnızca kullanıcıya aittir
    case personal
    /// Ortak ev: birden fazla ev arkadaşı görev döngüsünü ve misafir takvimini paylaşır
    case shared

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .personal: return "person.fill"
        case .shared: return "person.3.fill"
        }
    }

    public var localizedTitle: String {
        let isTurkish = LanguageManager.shared.locale.identifier.starts(with: "tr")
        switch self {
        case .personal: return isTurkish ? "Kişisel Ev" : "Personal Home"
        case .shared: return isTurkish ? "Ortak Ev" : "Shared Home"
        }
    }
}

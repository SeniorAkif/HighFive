import Foundation
import SwiftUI

/// Desteklenen diller
public enum AppLanguage: String, CaseIterable, Identifiable {
    case turkish = "tr"
    case english = "en"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .turkish: return "Türkçe"
        case .english: return "English"
        }
    }

    public var flagEmoji: String {
        switch self {
        case .turkish: return "🇹🇷"
        case .english: return "🇬🇧"
        }
    }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }
}

/// Uygulama dilini dinamik yöneten sınıf
public final class LanguageManager: ObservableObject {
    public static let shared = LanguageManager()

    @AppStorage("app_selected_language") public var selectedLanguageRaw: String = AppLanguage.turkish.rawValue {
        didSet {
            objectWillChange.send()
        }
    }

    public var currentLanguage: AppLanguage {
        get {
            AppLanguage(rawValue: selectedLanguageRaw) ?? .turkish
        }
        set {
            selectedLanguageRaw = newValue.rawValue
        }
    }

    public var locale: Locale {
        currentLanguage.locale
    }

    public init() {}

    /// Dili değiştirir
    public func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
}

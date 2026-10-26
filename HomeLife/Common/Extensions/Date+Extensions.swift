import Foundation

extension Date {
    /// Dile duyarlı göreceli tarih açıklaması ("Bugün" / "Today", "Yarın" / "Tomorrow", vb.)
    public var relativeFormattedText: String {
        let locale = LanguageManager.shared.locale
        let calendar = Calendar.current
        let isTurkish = locale.identifier.starts(with: "tr")

        if calendar.isDateInToday(self) {
            return isTurkish ? "Bugün" : "Today"
        } else if calendar.isDateInTomorrow(self) {
            return isTurkish ? "Yarın" : "Tomorrow"
        } else if calendar.isDateInYesterday(self) {
            return isTurkish ? "Dün" : "Yesterday"
        } else {
            let startToday = calendar.startOfDay(for: Date())
            let startSelf = calendar.startOfDay(for: self)
            let diff = calendar.dateComponents([.day], from: startToday, to: startSelf).day ?? 0
            
            if diff > 0 && diff < 7 {
                return isTurkish ? "\(diff) gün sonra" : "in \(diff) days"
            } else if diff < 0 && diff > -7 {
                return isTurkish ? "\(-diff) gün önce" : "\(-diff) days ago"
            } else {
                let formatter = DateFormatter()
                formatter.locale = locale
                formatter.dateFormat = "d MMMM"
                return formatter.string(from: self)
            }
        }
    }

    /// Tam tarih ve saat ("28 Ekim Salı, 14:30" / "28 October Tuesday, 14:30")
    public var fullFormattedText: String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.locale
        formatter.dateFormat = "d MMMM EEEE, HH:mm"
        return formatter.string(from: self)
    }

    /// Kısa gün ve ay ("28 Eki" / "28 Oct")
    public var shortDateText: String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.locale
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    /// Sadece saat ("18:00")
    public var timeOnlyText: String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.locale
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
}

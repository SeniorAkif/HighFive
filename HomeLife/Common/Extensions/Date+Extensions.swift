import Foundation

extension Date {
    /// Türkçe göreceli tarih açıklaması ("Bugün", "Yarın", "Dün", "2 gün sonra", vb.)
    public var relativeFormattedText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) {
            return "Bugün"
        } else if calendar.isDateInTomorrow(self) {
            return "Yarın"
        } else if calendar.isDateInYesterday(self) {
            return "Dün"
        } else {
            let startToday = calendar.startOfDay(for: Date())
            let startSelf = calendar.startOfDay(for: self)
            let diff = calendar.dateComponents([.day], from: startToday, to: startSelf).day ?? 0
            
            if diff > 0 && diff < 7 {
                return "\(diff) gün sonra"
            } else if diff < 0 && diff > -7 {
                return "\(-diff) gün önce"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "tr_TR")
                formatter.dateFormat = "d MMMM"
                return formatter.string(from: self)
            }
        }
    }

    /// Tam tarih ve saat ("28 Ekim Salı, 14:30")
    public var fullFormattedText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMMM EEEE, HH:mm"
        return formatter.string(from: self)
    }

    /// Kısa gün ve ay ("28 Eki")
    public var shortDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: self)
    }

    /// Sadece saat ("18:00")
    public var timeOnlyText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
}

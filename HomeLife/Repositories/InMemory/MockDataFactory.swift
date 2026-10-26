import Foundation

/// Ön tanımlı gerçekçi öğrenci evi verileri
public struct MockDataFactory {
    // Sabit UUID'ler sayesinde mock veriler birbiriyle tutarlı ilişki kurar
    public static let roommateAhmetId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    public static let roommateMehmetId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    public static let roommateBarisId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!

    public static func createRoommates() -> [Roommate] {
        return [
            Roommate(
                id: roommateAhmetId,
                name: "Ahmet Yılmaz",
                nickname: "Ahmet",
                avatarEmoji: "👨‍💻",
                avatarColorHex: "#4F46E5", // Indigo
                phoneNumber: "0555 123 4567",
                roomName: "Büyük Oda"
            ),
            Roommate(
                id: roommateMehmetId,
                name: "Mehmet Kaya",
                nickname: "Mehmet",
                avatarEmoji: "🎸",
                avatarColorHex: "#059669", // Emerald
                phoneNumber: "0555 987 6543",
                roomName: "Küçük Oda"
            ),
            Roommate(
                id: roommateBarisId,
                name: "Barış Demir",
                nickname: "Barış",
                avatarEmoji: "☕️",
                avatarColorHex: "#D97706", // Amber
                phoneNumber: "0555 555 4433",
                roomName: "Balkonlu Oda"
            )
        ]
    }

    public static func createChores() -> [Chore] {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let inTwoDays = calendar.date(byAdding: .day, value: 2, to: today) ?? today
        let inFourDays = calendar.date(byAdding: .day, value: 4, to: today) ?? today

        let order = [roommateAhmetId, roommateMehmetId, roommateBarisId]

        return [
            Chore(
                id: UUID(uuidString: "AAAA1111-0000-0000-0000-000000000001")!,
                title: "Bulaşık Yıkama & Makineyi Boşaltma",
                description: "Lavabodaki kirli tabakları makineye yerleştir ve temiz olanları dolaplara diz.",
                category: .kitchen,
                assignmentType: .rotating,
                rotationOrder: order,
                currentAssigneeIndex: 0, // Sıra Ahmet'te
                frequency: .daily,
                dueDate: today,
                lastCompletedDate: calendar.date(byAdding: .day, value: -1, to: today),
                lastCompletedById: roommateBarisId
            ),
            Chore(
                id: UUID(uuidString: "AAAA1111-0000-0000-0000-000000000002")!,
                title: "Çöpleri Dışarı Çıkarma",
                description: "Mutfak ve balkon çöp torbalarını bağlayıp akşam konteynere at.",
                category: .trash,
                assignmentType: .rotating,
                rotationOrder: order,
                currentAssigneeIndex: 1, // Sıra Mehmet'te
                frequency: .everyOtherDay,
                dueDate: tomorrow,
                lastCompletedDate: calendar.date(byAdding: .day, value: -2, to: today),
                lastCompletedById: roommateAhmetId
            ),
            Chore(
                id: UUID(uuidString: "AAAA1111-0000-0000-0000-000000000003")!,
                title: "Mutfak Temizliği & Ocak/Tezgah",
                description: "Mutfak tezgahını sil, ocağın yağını temizle ve yemek masasını düzenle.",
                category: .kitchen,
                assignmentType: .dedicated,
                dedicatedAssigneeId: roommateMehmetId, // Mehmet'in sabit sorumluluğu
                frequency: .weekly,
                dueDate: inTwoDays,
                lastCompletedDate: calendar.date(byAdding: .day, value: -4, to: today),
                lastCompletedById: roommateMehmetId
            ),
            Chore(
                id: UUID(uuidString: "AAAA1111-0000-0000-0000-000000000004")!,
                title: "Salon & Odaları Süpürme",
                description: "Salonu ve ortak alanları elektrikli süpürgeyle süpür, toz al.",
                category: .livingRoom,
                assignmentType: .dedicated,
                dedicatedAssigneeId: roommateAhmetId, // Ahmet'in sabit sorumluluğu
                frequency: .weekly,
                dueDate: inFourDays,
                lastCompletedDate: calendar.date(byAdding: .day, value: -6, to: today),
                lastCompletedById: roommateAhmetId
            ),
            Chore(
                id: UUID(uuidString: "AAAA1111-0000-0000-0000-000000000005")!,
                title: "Banyo & Tuvalet Temizliği",
                description: "Lavabo, klozet ve duşakabini dezenfektanla temizle, paspası yıka.",
                category: .bathroom,
                assignmentType: .rotating,
                rotationOrder: order,
                currentAssigneeIndex: 2, // Sıra Barış'ta
                frequency: .weekly,
                dueDate: inTwoDays,
                lastCompletedDate: calendar.date(byAdding: .day, value: -5, to: today),
                lastCompletedById: roommateMehmetId
            )
        ]
    }

    public static func createGuestVisits() -> [GuestVisit] {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let threeDaysLater = calendar.date(byAdding: .day, value: 3, to: today) ?? today
        let nextWeekendStart = calendar.date(byAdding: .day, value: 5, to: today) ?? today
        let nextWeekendEnd = calendar.date(byAdding: .day, value: 7, to: today) ?? today

        return [
            GuestVisit(
                id: UUID(uuidString: "BBBB2222-0000-0000-0000-000000000001")!,
                hostRoommateId: roommateMehmetId,
                guestName: "Mert & Can (Liseden)",
                guestCount: 2,
                startDate: tomorrow,
                endDate: threeDaysLater,
                isOvernight: true,
                stayLocation: "Salonda çekyat",
                notes: "Konsere gideceğiz, gece geç gelebiliriz. Salonda yatacaklar.",
                status: .upcoming
            ),
            GuestVisit(
                id: UUID(uuidString: "BBBB2222-0000-0000-0000-000000000002")!,
                hostRoommateId: roommateAhmetId,
                guestName: "Kuzenim Eren",
                guestCount: 1,
                startDate: nextWeekendStart,
                endDate: nextWeekendEnd,
                isOvernight: true,
                stayLocation: "Ahmet'in odası",
                notes: "Vize sınavı için Ankara'dan gelecek, odamda şişme yatakta kalacak.",
                status: .upcoming
            )
        ]
    }

    public static func createInitialLogs() -> [ChoreLog] {
        let calendar = Calendar.current
        let today = Date()
        return [
            ChoreLog(
                choreId: UUID(uuidString: "AAAA1111-0000-0000-0000-000000000001")!,
                choreTitle: "Bulaşık Yıkama & Makineyi Boşaltma",
                completedByRoommateId: roommateBarisId,
                completedAt: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                notes: "Tencereler elde yıkandı, makine çalıştırıldı."
            ),
            ChoreLog(
                choreId: UUID(uuidString: "AAAA1111-0000-0000-0000-000000000002")!,
                choreTitle: "Çöpleri Dışarı Çıkarma",
                completedByRoommateId: roommateAhmetId,
                completedAt: calendar.date(byAdding: .day, value: -2, to: today) ?? today,
                notes: "Geri dönüşüm de atıldı."
            )
        ]
    }
}

import SwiftUI

public struct ChoreHistorySheet: View {
    @Environment(\.dismiss) private var dismiss
    public let chore: Chore
    public let logs: [ChoreLog]
    public let roommates: [Roommate]

    public init(chore: Chore, logs: [ChoreLog], roommates: [Roommate]) {
        self.chore = chore
        self.logs = logs
        self.roommates = roommates
    }

    private func roommate(for id: UUID) -> Roommate? {
        roommates.first { $0.id == id }
    }

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Görev Bilgisi")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(chore.title)
                            .font(.headline)
                        Text("Kategori: \(chore.category.rawValue) • Sıklık: \(chore.frequency.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Tamamlama ve Devir Geçmişi")) {
                    if logs.isEmpty {
                        Text("Henüz tamamlanma kaydı bulunmuyor.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(logs) { log in
                            let person = roommate(for: log.completedByRoommateId)
                            HStack(alignment: .top, spacing: 12) {
                                AvatarBadgeView(
                                    emoji: person?.avatarEmoji ?? "👤",
                                    initials: person?.initials ?? "",
                                    colorHex: person?.avatarColorHex ?? "#4F46E5",
                                    size: 32
                                )

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(person?.displayName ?? "Bilinmeyen")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Spacer()

                                        Text(log.completedAt.fullFormattedText)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    if let notes = log.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Görev Geçmişi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

import SwiftUI

public struct AddChoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let roommates: [Roommate]
    public let onSave: (String, String, ChoreCategory, [UUID], ChoreFrequency, Date) -> Void

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: ChoreCategory = .kitchen
    @State private var frequency: ChoreFrequency = .weekly
    @State private var dueDate: Date = Date()
    @State private var selectedRoommateIds: [UUID] = []

    public init(
        roommates: [Roommate],
        onSave: @escaping (String, String, ChoreCategory, [UUID], ChoreFrequency, Date) -> Void
    ) {
        self.roommates = roommates
        self.onSave = onSave
        _selectedRoommateIds = State(initialValue: roommates.map { $0.id })
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Görev Bilgileri")) {
                    TextField("Görev Adı (örn. Bulaşık Yıkama)", text: $title)

                    TextField("Açıklama veya İpuçları (İsteğe bağlı)", text: $description)

                    Picker("Kategori", selection: $category) {
                        ForEach(ChoreCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }

                    Picker("Tekrarlanma Sıklığı", selection: $frequency) {
                        ForEach(ChoreFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    DatePicker("İlk Bitiş Tarihi", selection: $dueDate, displayedComponents: [.date])
                }

                Section(
                    header: Text("Sırayla Yapacak Ev Arkadaşları"),
                    footer: Text("Görev tamamlandıkça sıra bu sıraya göre otomatik devredilecektir.")
                ) {
                    ForEach(roommates) { roommate in
                        let isSelected = selectedRoommateIds.contains(roommate.id)
                        Button {
                            if isSelected {
                                selectedRoommateIds.removeAll { $0 == roommate.id }
                            } else {
                                selectedRoommateIds.append(roommate.id)
                            }
                        } label: {
                            HStack {
                                AvatarBadgeView(
                                    emoji: roommate.avatarEmoji,
                                    initials: roommate.initials,
                                    colorHex: roommate.avatarColorHex,
                                    size: 30
                                )
                                Text(roommate.displayName)
                                    .foregroundColor(.primary)

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.primary)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Yeni Ev İşi Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        let finalOrder = selectedRoommateIds.isEmpty ? roommates.map { $0.id } : selectedRoommateIds
                        onSave(title, description, category, finalOrder, frequency, dueDate)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

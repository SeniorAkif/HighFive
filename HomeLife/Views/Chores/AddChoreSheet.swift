import SwiftUI

public struct AddChoreSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let roommates: [Roommate]
    /// Varsayılan seçilecek ev arkadaşı (oturumdaki "Ben" kullanıcısı)
    public let preferredRoommateId: UUID?
    public let onSave: (String, String, ChoreCategory, ChoreAssignmentType, UUID?, [UUID], ChoreFrequency, Date) -> Void

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var category: ChoreCategory = .kitchen
    @State private var assignmentType: ChoreAssignmentType = .rotating
    @State private var dedicatedAssigneeId: UUID?
    @State private var frequency: ChoreFrequency = .weekly
    @State private var dueDate: Date = Date()
    @State private var selectedRoommateIds: [UUID] = []

    public init(
        roommates: [Roommate],
        preferredRoommateId: UUID? = nil,
        onSave: @escaping (String, String, ChoreCategory, ChoreAssignmentType, UUID?, [UUID], ChoreFrequency, Date) -> Void
    ) {
        self.roommates = roommates
        self.preferredRoommateId = preferredRoommateId
        self.onSave = onSave
        _dedicatedAssigneeId = State(initialValue: Self.defaultRoommateId(in: roommates, preferred: preferredRoommateId))
        _selectedRoommateIds = State(initialValue: roommates.map { $0.id })
    }

    /// Sıralı döngüde seçim yapılmadıysa tüm ev halkı sıraya girer
    private var finalRotationOrder: [UUID] {
        selectedRoommateIds.isEmpty ? roommates.map { $0.id } : selectedRoommateIds
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        switch assignmentType {
        case .dedicated: return dedicatedAssigneeId != nil
        case .rotating: return !finalRotationOrder.isEmpty
        }
    }

    /// Tercih edilen kişi listede varsa onu, yoksa ilk kişiyi seçer
    private static func defaultRoommateId(in roommates: [Roommate], preferred: UUID?) -> UUID? {
        if let preferred, roommates.contains(where: { $0.id == preferred }) {
            return preferred
        }
        return roommates.first?.id
    }

    /// Liste geç yüklendiğinde veya seçim geçersiz kaldığında varsayılanları yeniden atar
    private func ensureValidSelection() {
        let ids = Set(roommates.map { $0.id })
        if dedicatedAssigneeId == nil || !ids.contains(dedicatedAssigneeId!) {
            dedicatedAssigneeId = Self.defaultRoommateId(in: roommates, preferred: preferredRoommateId)
        }
        selectedRoommateIds.removeAll { !ids.contains($0) }
        if selectedRoommateIds.isEmpty {
            selectedRoommateIds = roommates.map { $0.id }
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Görev Bilgileri")) {
                    TextField("Görev Adı (örn. Mutfak Temizliği)", text: $title)

                    TextField("Açıklama veya İpuçları (İsteğe bağlı)", text: $description)

                    Picker("Kategori", selection: $category) {
                        ForEach(ChoreCategory.allCases) { cat in
                            Label(cat.localizedTitle, systemImage: cat.iconName)
                                .tag(cat)
                        }
                    }

                    Picker("Tekrarlanma Sıklığı", selection: $frequency) {
                        ForEach(ChoreFrequency.allCases) { freq in
                            Text(freq.localizedTitle).tag(freq)
                        }
                    }

                    DatePicker("İlk Bitiş Tarihi", selection: $dueDate, displayedComponents: [.date])
                }

                Section(header: Text("Paylaşım & Sorumluluk Modeli")) {
                    Picker("Görev Türü", selection: $assignmentType) {
                        ForEach(ChoreAssignmentType.allCases) { type in
                            Label(type.localizedTitle, systemImage: type.iconName)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if roommates.isEmpty {
                    Section {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Ev arkadaşları yükleniyor…")
                                .foregroundColor(.secondary)
                        }
                    }
                } else if assignmentType == .dedicated {
                    Section(
                        header: Text("Sorumlu Ev Arkadaşı"),
                        footer: Text("Bu iş seçilen kişinin daimi sorumluluğunda kalır. Görev tamamlandığında sıra değişmez.")
                    ) {
                        ForEach(roommates) { roommate in
                            let isSelected = dedicatedAssigneeId == roommate.id
                            Button {
                                dedicatedAssigneeId = roommate.id
                            } label: {
                                HStack {
                                    AvatarBadgeView(
                                        emoji: roommate.avatarEmoji,
                                        initials: roommate.initials,
                                        colorHex: roommate.avatarColorHex,
                                        size: 30
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(roommate.displayName)
                                            .foregroundColor(.primary)
                                        if let room = roommate.roomName {
                                            Text(room)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }

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
                } else {
                    Section(
                        header: Text("Sırayla Yapacak Ev Arkadaşları"),
                        footer: Text("Görev tamamlandıkça sıra bu sıraya göre otomatik sonraki kişiye devredilir.")
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
                        onSave(title, description, category, assignmentType, dedicatedAssigneeId, finalRotationOrder, frequency, dueDate)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: ensureValidSelection)
            .onChange(of: roommates) { _, _ in
                ensureValidSelection()
            }
        }
    }
}

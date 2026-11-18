import SwiftUI

public struct AddGuestSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let roommates: [Roommate]
    /// Varsayılan seçilecek ev arkadaşı (oturumdaki "Ben" kullanıcısı)
    public let preferredRoommateId: UUID?
    public let onSave: (UUID, String, Int, Date, Date, Bool, String, String) -> Void

    @State private var selectedHostId: UUID?
    @State private var guestName: String = ""
    @State private var guestCount: Int = 1
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var isOvernight: Bool = true
    @State private var stayLocation: String = "Salon Çekyat"
    @State private var notes: String = ""

    public init(
        roommates: [Roommate],
        preferredRoommateId: UUID? = nil,
        onSave: @escaping (UUID, String, Int, Date, Date, Bool, String, String) -> Void
    ) {
        self.roommates = roommates
        self.preferredRoommateId = preferredRoommateId
        self.onSave = onSave
        _selectedHostId = State(initialValue: Self.defaultRoommateId(in: roommates, preferred: preferredRoommateId))
    }

    private var canSave: Bool {
        !guestName.trimmingCharacters(in: .whitespaces).isEmpty && selectedHostId != nil
    }

    /// Tercih edilen kişi listede varsa onu, yoksa ilk kişiyi seçer
    private static func defaultRoommateId(in roommates: [Roommate], preferred: UUID?) -> UUID? {
        if let preferred, roommates.contains(where: { $0.id == preferred }) {
            return preferred
        }
        return roommates.first?.id
    }

    /// Liste geç yüklendiğinde veya seçim geçersiz kaldığında varsayılanı yeniden atar
    private func ensureValidSelection() {
        if let selectedHostId, roommates.contains(where: { $0.id == selectedHostId }) {
            return
        }
        selectedHostId = Self.defaultRoommateId(in: roommates, preferred: preferredRoommateId)
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Ev Sahibi & Misafir Bilgileri")) {
                    if roommates.isEmpty {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Ev arkadaşları yükleniyor…")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Kimin Misafiri?", selection: $selectedHostId) {
                            ForEach(roommates) { roommate in
                                Text(roommate.displayName).tag(Optional(roommate.id))
                            }
                        }
                    }

                    TextField("Misafir Adı / Kimler Geliyor?", text: $guestName)

                    Stepper("Kişi Sayısı: \(guestCount)", value: $guestCount, in: 1...10)
                }

                Section(header: Text("Tarih & Konaklama")) {
                    DatePicker("Geliş Tarihi", selection: $startDate, displayedComponents: [.date, .hourAndMinute])

                    DatePicker("Ayrılış Tarihi", selection: $endDate, in: startDate..., displayedComponents: [.date, .hourAndMinute])

                    Toggle("Yatılı Kalacak mı?", isOn: $isOvernight)

                    if isOvernight {
                        TextField("Nerede Kalacak? (örn. Kendi odam, Salon)", text: $stayLocation)
                    }
                }

                Section(header: Text("Notlar & Ev Halkına Mesaj")) {
                    TextField("Örn. Akşam sessiz olmamız gerek, konsere gideceğiz vs.", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Yeni Misafir Kaydı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        guard let hostId = selectedHostId else { return }
                        onSave(hostId, guestName, guestCount, startDate, endDate, isOvernight, stayLocation, notes)
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

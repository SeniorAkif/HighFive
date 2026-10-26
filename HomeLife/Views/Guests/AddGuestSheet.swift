import SwiftUI

public struct AddGuestSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let roommates: [Roommate]
    public let onSave: (UUID, String, Int, Date, Date, Bool, String, String) -> Void

    @State private var selectedHostId: UUID
    @State private var guestName: String = ""
    @State private var guestCount: Int = 1
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var isOvernight: Bool = true
    @State private var stayLocation: String = "Salon Çekyat"
    @State private var notes: String = ""

    public init(
        roommates: [Roommate],
        onSave: @escaping (UUID, String, Int, Date, Date, Bool, String, String) -> Void
    ) {
        self.roommates = roommates
        self.onSave = onSave
        _selectedHostId = State(initialValue: roommates.first?.id ?? UUID())
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Ev Sahibi & Misafir Bilgileri")) {
                    Picker("Kimin Misafiri?", selection: $selectedHostId) {
                        ForEach(roommates) { roommate in
                            Text(roommate.displayName).tag(roommate.id)
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
                        onSave(selectedHostId, guestName, guestCount, startDate, endDate, isOvernight, stayLocation, notes)
                        dismiss()
                    }
                    .disabled(guestName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

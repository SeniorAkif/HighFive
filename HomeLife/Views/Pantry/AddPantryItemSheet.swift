import SwiftUI

/// Yeni ürün ekleme / mevcut ürünü düzenleme formu
public struct AddPantryItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared

    public let roommates: [Roommate]
    /// Varsayılan "ekleyen" (oturumdaki "Ben" kullanıcısı)
    public let preferredRoommateId: UUID?
    public let houseMode: HouseMode
    /// Dolu gelirse form düzenleme modunda açılır
    public let existingItem: PantryItem?
    public let onSave: (PantryItem) -> Void

    @State private var name: String
    @State private var quantity: Double
    @State private var unit: PantryUnit
    @State private var category: PantryCategory
    @State private var location: PantryStorageLocation
    @State private var hasExpirationDate: Bool
    @State private var expirationDate: Date
    @State private var addedByRoommateId: UUID?
    /// Kullanıcı saklama yerini elle seçtiyse kategori değişiminde otomatik öneri uygulanmaz
    @State private var isLocationManuallySet: Bool

    public init(
        roommates: [Roommate],
        preferredRoommateId: UUID?,
        houseMode: HouseMode,
        existingItem: PantryItem? = nil,
        defaultLocation: PantryStorageLocation? = nil,
        onSave: @escaping (PantryItem) -> Void
    ) {
        self.roommates = roommates
        self.preferredRoommateId = preferredRoommateId
        self.houseMode = houseMode
        self.existingItem = existingItem
        self.onSave = onSave

        let defaultExpiry = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        _name = State(initialValue: existingItem?.name ?? "")
        _quantity = State(initialValue: existingItem?.quantity ?? 1)
        _unit = State(initialValue: existingItem?.unit ?? .piece)
        _category = State(initialValue: existingItem?.category ?? .dairy)
        _location = State(initialValue: existingItem?.location ?? defaultLocation ?? PantryCategory.dairy.suggestedLocation)
        _hasExpirationDate = State(initialValue: existingItem?.expirationDate != nil)
        _expirationDate = State(initialValue: existingItem?.expirationDate ?? defaultExpiry)
        _addedByRoommateId = State(initialValue: existingItem?.addedByRoommateId ?? Self.defaultRoommateId(in: roommates, preferred: preferredRoommateId))
        _isLocationManuallySet = State(initialValue: existingItem != nil || defaultLocation != nil)
    }

    private var isEditing: Bool { existingItem != nil }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        // Düzenlemede "tükendi" (0) olarak kaydetmeye izin verilir
        !trimmedName.isEmpty && (isEditing ? quantity >= 0 : quantity > 0)
    }

    private static func defaultRoommateId(in roommates: [Roommate], preferred: UUID?) -> UUID? {
        if let preferred, roommates.isEmpty || roommates.contains(where: { $0.id == preferred }) {
            return preferred
        }
        return roommates.first?.id
    }

    /// Liste geç yüklendiğinde veya seçim geçersiz kaldığında varsayılanı yeniden atar
    private func ensureValidSelection() {
        guard !isEditing else { return }
        if let addedByRoommateId, roommates.contains(where: { $0.id == addedByRoommateId }) {
            return
        }
        addedByRoommateId = Self.defaultRoommateId(in: roommates, preferred: preferredRoommateId)
    }

    public var body: some View {
        NavigationStack {
            Form {
                if !isEditing {
                    Section {
                        AIPhotoImportCard()
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                Section(header: Text("Ürün Bilgileri")) {
                    TextField("Ürün Adı (örn. Süt, Domates)", text: $name)
                        .textInputAutocapitalization(.sentences)

                    Picker("Kategori", selection: $category) {
                        ForEach(PantryCategory.allCases) { category in
                            Text("\(category.emoji) \(category.localizedTitle)").tag(category)
                        }
                    }

                    Picker("Nerede?", selection: locationBinding) {
                        ForEach(PantryStorageLocation.allCases) { location in
                            Text(location.localizedTitle).tag(location)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Miktar")) {
                    HStack {
                        TextField("Miktar", value: $quantity, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 100)

                        Spacer()

                        Stepper(
                            "",
                            value: $quantity,
                            in: 0...unit.maxQuantity,
                            step: unit.quickStep
                        )
                        .labelsHidden()
                    }

                    Picker("Birim", selection: $unit) {
                        ForEach(PantryUnit.allCases) { unit in
                            Text(unit.localizedTitle).tag(unit)
                        }
                    }
                }

                Section(header: Text("Son Kullanma Tarihi")) {
                    Toggle("SKT Ekle", isOn: $hasExpirationDate.animation())

                    if hasExpirationDate {
                        DatePicker("SKT", selection: $expirationDate, displayedComponents: .date)
                    }
                }

                if houseMode == .shared {
                    Section(header: Text("Ortak Ev")) {
                        if roommates.isEmpty {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Ev arkadaşları yükleniyor…")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Picker("Kim Ekledi?", selection: $addedByRoommateId) {
                                ForEach(roommates) { roommate in
                                    Text(roommate.displayName).tag(Optional(roommate.id))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Ürünü Düzenle" : "Yeni Ürün Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        onSave(makeItem())
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: ensureValidSelection)
            .onChange(of: roommates) { _, _ in
                ensureValidSelection()
            }
            .onChange(of: category) { _, newCategory in
                guard !isLocationManuallySet else { return }
                location = newCategory.suggestedLocation
            }
        }
    }

    private var locationBinding: Binding<PantryStorageLocation> {
        Binding(
            get: { location },
            set: { newValue in
                location = newValue
                isLocationManuallySet = true
            }
        )
    }

    private func makeItem() -> PantryItem {
        let now = Date()
        return PantryItem(
            id: existingItem?.id ?? UUID(),
            name: trimmedName,
            quantity: max(0, quantity),
            unit: unit,
            category: category,
            location: location,
            expirationDate: hasExpirationDate ? Calendar.current.startOfDay(for: expirationDate) : nil,
            addedByRoommateId: addedByRoommateId ?? existingItem?.addedByRoommateId ?? preferredRoommateId,
            createdAt: existingItem?.createdAt ?? now,
            updatedAt: now
        )
    }
}

/// Gelecekteki AI entegrasyonu için yer tutucu kart.
/// Fotoğraftan ürünleri otomatik tanıma özelliği aktifleşene kadar pasif (disabled) durur.
public struct AIPhotoImportCard: View {
    public init() {}

    public var body: some View {
        Button {
            // TODO: AI destekli fotoğraf → ürün listesi akışı burada başlatılacak
        } label: {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.2))
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("Yakında (AI)")
                            .font(.caption2)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.25)))
                    .foregroundColor(.white)

                    Text("Fotoğraf Yükle (AI ile Otomatik Ekle)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Buzdolabının veya market fişinin fotoğrafını çek, ürünler otomatik eklensin.")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.primaryGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            )
            .saturation(0.55)
            .opacity(0.8)
        }
        .buttonStyle(.plain)
        .disabled(true)
        .accessibilityHint(Text("Bu özellik yakında aktifleşecek"))
    }
}

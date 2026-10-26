import SwiftUI

public struct AddRoommateSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let onSave: (String, String?, String, String, String?, String?) -> Void

    @State private var name: String = ""
    @State private var nickname: String = ""
    @State private var avatarEmoji: String = "👤"
    @State private var selectedColorHex: String = "#4F46E5"
    @State private var roomName: String = ""
    @State private var phoneNumber: String = ""

    private let availableEmojis = ["👤", "👨‍💻", "👩‍💻", "🎸", "☕️", "🍕", "🎮", "📚", "🎨", "⚽️", "🎧", "🏋️"]
    private let availableColors = ["#4F46E5", "#059669", "#D97706", "#DC2626", "#7C3AED", "#2563EB", "#DB2777"]

    public init(onSave: @escaping (String, String?, String, String, String?, String?) -> Void) {
        self.onSave = onSave
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad Soyad (örn. Ali Can)", text: $name)

                    TextField("Takma Ad (İsteğe bağlı)", text: $nickname)

                    TextField("Oda Adı (örn. Balkonlu Oda)", text: $roomName)

                    TextField("Telefon Numarası (İsteğe bağlı)", text: $phoneNumber)
                        .keyboardType(.phonePad)
                }

                Section(header: Text("Avatar & Renk")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Emoji Seç:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(availableEmojis, id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.title2)
                                        .padding(8)
                                        .background(avatarEmoji == emoji ? Color.primary.opacity(0.12) : Color.clear)
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            avatarEmoji = emoji
                                        }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Renk Teması:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColorHex == hex ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColorHex = hex
                                    }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Yeni Ev Arkadaşı Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        onSave(
                            name,
                            nickname.isEmpty ? nil : nickname,
                            avatarEmoji,
                            selectedColorHex,
                            phoneNumber.isEmpty ? nil : phoneNumber,
                            roomName.isEmpty ? nil : roomName
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

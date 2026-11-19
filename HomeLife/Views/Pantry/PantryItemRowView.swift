import SwiftUI

public struct PantryItemRowView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    public let item: PantryItem
    /// Yalnızca ortak ev modunda dolu gelir; kişisel modda ekleyen bilgisi gizlenir
    public let addedBy: Roommate?
    public let onIncrement: () -> Void
    public let onDecrement: () -> Void
    public let onEdit: () -> Void
    public let onDelete: () -> Void

    private var isTurkish: Bool {
        LanguageManager.shared.locale.identifier.starts(with: "tr")
    }

    public init(
        item: PantryItem,
        addedBy: Roommate?,
        onIncrement: @escaping () -> Void,
        onDecrement: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = item
        self.addedBy = addedBy
        self.onIncrement = onIncrement
        self.onDecrement = onDecrement
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    private var expiryStatus: PantryExpiryStatus {
        item.expiryStatus()
    }

    /// Tükenen ürünlerde SKT vurgusu yapılmaz
    private var highlightColor: Color? {
        guard !item.isDepleted, let hex = expiryStatus.colorHex else { return nil }
        return Color(hex: hex)
    }

    public var body: some View {
        GlassCardView(padding: 14) {
            HStack(alignment: .center, spacing: 12) {
                categoryBadge

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(item.isDepleted ? .secondary : .primary)
                        .strikethrough(item.isDepleted)
                        .lineLimit(2)

                    HStack(spacing: 4) {
                        Image(systemName: item.location.iconName)
                        Text(item.location.localizedTitle)
                        Text("•")
                        Text(item.category.localizedTitle)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                    statusPills

                    if let addedBy {
                        HStack(spacing: 4) {
                            Text("Ekleyen:")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            AvatarBadgeView(
                                emoji: addedBy.avatarEmoji,
                                initials: addedBy.initials,
                                colorHex: addedBy.avatarColorHex,
                                size: 16
                            )

                            Text(addedBy.displayName)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(Color(hex: addedBy.avatarColorHex))
                        }
                    }
                }

                Spacer(minLength: 4)

                quantityControl
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(highlightColor ?? .clear, lineWidth: 1.5)
        )
        .opacity(item.isDepleted ? 0.7 : 1)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .contextMenu {
            Button(action: onEdit) {
                Label("Düzenle", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Ürünü Sil", systemImage: "trash")
            }
        }
    }

    // MARK: - Alt Bileşenler

    private var categoryBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: item.category.colorHex).opacity(0.15))
            Text(item.category.emoji)
                .font(.system(size: 22))
        }
        .frame(width: 44, height: 44)
    }

    @ViewBuilder
    private var statusPills: some View {
        if item.isDepleted {
            StatusPillView(
                text: isTurkish ? "Tükendi" : "Out of stock",
                icon: "xmark.circle.fill",
                color: .secondary,
                style: .subtle
            )
        } else if let expiryText {
            StatusPillView(
                text: expiryText,
                icon: expiryIcon,
                color: highlightColor ?? .secondary,
                style: expiryStatus == .expired ? .solid : .subtle
            )
        }
    }

    private var expiryIcon: String {
        switch expiryStatus {
        case .expired: return "exclamationmark.triangle.fill"
        case .expiresToday, .expiringSoon: return "clock.badge.exclamationmark"
        case .fresh, .noDate: return "calendar"
        }
    }

    private var expiryText: String? {
        guard let expirationDate = item.expirationDate,
              let days = item.daysUntilExpiration() else { return nil }

        switch expiryStatus {
        case .expired:
            let ago = -days
            return isTurkish ? "SKT geçti (\(ago) gün önce)" : "Expired (\(ago) \(ago == 1 ? "day" : "days") ago)"
        case .expiresToday:
            return isTurkish ? "SKT bugün" : "Expires today"
        case .expiringSoon:
            return isTurkish ? "\(days) gün kaldı" : "\(days) \(days == 1 ? "day" : "days") left"
        case .fresh:
            return isTurkish ? "SKT: \(expirationDate.shortDateText)" : "Exp: \(expirationDate.shortDateText)"
        case .noDate:
            return nil
        }
    }

    private var quantityControl: some View {
        VStack(spacing: 6) {
            Text(item.quantityWithUnitText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundColor(item.isDepleted ? .secondary : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 0) {
                quantityButton(systemImage: "minus", isEnabled: !item.isDepleted, action: onDecrement)
                    .accessibilityLabel(Text("Azalt"))

                Divider()
                    .frame(height: 18)

                quantityButton(systemImage: "plus", isEnabled: true, action: onIncrement)
                    .accessibilityLabel(Text("Artır"))
            }
            .background(
                Capsule()
                    .fill(AppTheme.primary.opacity(0.1))
            )
        }
        .frame(minWidth: 84)
    }

    private func quantityButton(systemImage: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 38, height: 30)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundColor(isEnabled ? AppTheme.primary : .secondary.opacity(0.5))
        .disabled(!isEnabled)
    }
}

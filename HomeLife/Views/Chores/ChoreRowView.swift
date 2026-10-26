import SwiftUI

public struct ChoreRowView: View {
    public let chore: Chore
    public let roommates: [Roommate]
    public let onComplete: () -> Void
    public let onSkip: () -> Void
    public let onReassign: (Roommate) -> Void
    public let onViewHistory: () -> Void
    public let onDelete: () -> Void

    public init(
        chore: Chore,
        roommates: [Roommate],
        onComplete: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onReassign: @escaping (Roommate) -> Void,
        onViewHistory: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.chore = chore
        self.roommates = roommates
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.onReassign = onReassign
        self.onViewHistory = onViewHistory
        self.onDelete = onDelete
    }

    private var currentAssignee: Roommate? {
        guard let id = chore.currentAssigneeId else { return nil }
        return roommates.first { $0.id == id }
    }

    private var orderedRoommates: [Roommate] {
        chore.rotationOrder.compactMap { id in
            roommates.first { $0.id == id }
        }
    }

    public var body: some View {
        GlassCardView(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                // Üst Kısım: Kategori, Başlık, Paylaşım Türü Rozeti ve Menü
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: chore.category.iconName)
                        .font(.title3)
                        .foregroundColor(Color(hex: chore.category.colorHex))
                        .frame(width: 40, height: 40)
                        .background(Color(hex: chore.category.colorHex).opacity(0.15))
                        .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(chore.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }

                        if !chore.description.isEmpty {
                            Text(chore.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Menu {
                        if chore.assignmentType == .rotating {
                            Button(action: onSkip) {
                                Label("Sırayı Sonrakine Devret (Atla)", systemImage: "arrow.right.circle")
                            }
                        }

                        Menu {
                            ForEach(roommates) { roommate in
                                Button {
                                    onReassign(roommate)
                                } label: {
                                    HStack {
                                        Text(roommate.displayName)
                                        if roommate.id == chore.currentAssigneeId {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Sorumluyu Değiştir", systemImage: "person.2.circle")
                        }

                        Button(action: onViewHistory) {
                            Label("Görev Geçmişi", systemImage: "clock.arrow.circlepath")
                        }
                        Divider()
                        Button(role: .destructive, action: onDelete) {
                            Label("Görevi Sil", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                    }
                }

                // Görev Türü Rozeti
                HStack(spacing: 6) {
                    StatusPillView(
                        text: chore.assignmentType.localizedTitle,
                        icon: chore.assignmentType.iconName,
                        color: chore.assignmentType == .dedicated ? AppTheme.secondary : AppTheme.primary,
                        style: .subtle
                    )

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(chore.frequency.localizedTitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()
                }

                Divider()

                // Orta Kısım: Sorumlu Kişi ve Bitiş Tarihi
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if chore.assignmentType == .dedicated {
                            Text("SABİT SORUMLU")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        } else {
                            Text("ŞU ANKİ SIRA")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }

                        if let assignee = currentAssignee {
                            HStack(spacing: 6) {
                                AvatarBadgeView(
                                    emoji: assignee.avatarEmoji,
                                    initials: assignee.initials,
                                    colorHex: assignee.avatarColorHex,
                                    size: 26
                                )
                                Text(assignee.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(hex: assignee.avatarColorHex))
                            }
                        } else {
                            Text("Atanmamış")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("BİTİŞ ZAMANI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)

                        StatusPillView(
                            text: chore.dueDate.relativeFormattedText,
                            icon: chore.isOverdue ? "exclamationmark.triangle.fill" : "calendar",
                            color: chore.isOverdue ? AppTheme.danger : (chore.isDueToday ? AppTheme.warning : AppTheme.primary),
                            style: .subtle
                        )
                    }
                }

                // Alt Kısım: Sıralı Döngü veya Sabit Görev Açıklaması
                if chore.assignmentType == .rotating {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Döngü Sırası:")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Array(orderedRoommates.enumerated()), id: \.offset) { index, roommate in
                                    let isCurrent = (index == chore.currentAssigneeIndex % max(1, chore.rotationOrder.count))
                                    HStack(spacing: 4) {
                                        Text("\(index + 1).")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(isCurrent ? Color(hex: roommate.avatarColorHex) : .secondary)

                                        Text(roommate.displayName)
                                            .font(.caption2)
                                            .fontWeight(isCurrent ? .bold : .regular)
                                            .foregroundColor(isCurrent ? Color(hex: roommate.avatarColorHex) : .secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(isCurrent ? Color(hex: roommate.avatarColorHex).opacity(0.18) : Color.primary.opacity(0.04))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isCurrent ? Color(hex: roommate.avatarColorHex) : Color.clear, lineWidth: 1.5)
                                    )

                                    if index < orderedRoommates.count - 1 {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "pin.circle.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondary)
                        Text("Bu görev kalıcı olarak paylaşıldı. Tamamlandığında sorumlusu değişmez.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }

                // Tamamla Butonu
                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        if chore.assignmentType == .dedicated {
                            Text("Görevi Tamamladım")
                                .fontWeight(.semibold)
                        } else {
                            Text("Sıramı Tamamladım (Devret)")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.primaryGradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }
}

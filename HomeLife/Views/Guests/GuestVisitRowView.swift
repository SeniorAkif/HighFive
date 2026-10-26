import SwiftUI

public struct GuestVisitRowView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    public let visit: GuestVisit
    public let host: Roommate?
    public let onStatusChange: (GuestVisitStatus) -> Void
    public let onDelete: () -> Void

    private var isTurkish: Bool {
        LanguageManager.shared.locale.identifier.starts(with: "tr")
    }

    public init(
        visit: GuestVisit,
        host: Roommate?,
        onStatusChange: @escaping (GuestVisitStatus) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.visit = visit
        self.host = host
        self.onStatusChange = onStatusChange
        self.onDelete = onDelete
    }

    public var body: some View {
        GlassCardView(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Üst Kısım: Misafir adı, kişi sayısı, durum ve menü
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(visit.guestName)
                                .font(.headline)
                                .foregroundColor(.primary)

                            if visit.guestCount > 1 {
                                Text(isTurkish ? "\(visit.guestCount) Kişi" : "\(visit.guestCount) Guests")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.primary.opacity(0.08))
                                    .cornerRadius(6)
                            }
                        }

                        if let host = host {
                            HStack(spacing: 4) {
                                Text("Ev Sahibi:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                AvatarBadgeView(
                                    emoji: host.avatarEmoji,
                                    initials: host.initials,
                                    colorHex: host.avatarColorHex,
                                    size: 18
                                )

                                Text(host.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: host.avatarColorHex))
                            }
                        }
                    }

                    Spacer()

                    Menu {
                        Section("Durumu Güncelle") {
                            ForEach(GuestVisitStatus.allCases) { status in
                                Button {
                                    onStatusChange(status)
                                } label: {
                                    HStack {
                                        Text(status.localizedTitle)
                                        if visit.status == status {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                        Divider()
                        Button(role: .destructive, action: onDelete) {
                            Label("Ziyareti Sil", systemImage: "trash")
                        }
                    } label: {
                        StatusPillView(
                            text: visit.status.localizedTitle,
                            color: Color(hex: visit.status.badgeColorHex),
                            style: .subtle
                        )
                    }
                }

                Divider()

                // Orta Kısım: Tarih ve Konaklama Yeri
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(AppTheme.primary)

                        Text("\(visit.startDate.shortDateText) - \(visit.endDate.shortDateText)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: visit.isOvernight ? "bed.double.fill" : "sun.max.fill")
                            .font(.caption)
                            .foregroundColor(visit.isOvernight ? AppTheme.secondary : AppTheme.warning)

                        if visit.isOvernight {
                            Text(isTurkish ? "Yatılı (\(visit.durationInDays) gece)" : "Overnight (\(visit.durationInDays) \(visit.durationInDays == 1 ? "night" : "nights"))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text(isTurkish ? "Günübirlik" : "Day Visit")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()
                }

                // Alt Kısım: Konum ve Not
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Text("Kalacağı Yer:")
                            Text(visit.stayLocation)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }

                    if !visit.notes.isEmpty {
                        HStack(spacing: 4) {
                            Text("Not:")
                            Text(visit.notes)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .padding(.top, 2)
                    }
                }
            }
        }
    }
}

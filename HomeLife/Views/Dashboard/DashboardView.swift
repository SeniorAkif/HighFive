import SwiftUI

public struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    public init(container: DependencyContainer) {
        _viewModel = StateObject(
            wrappedValue: DashboardViewModel(
                roommateRepository: container.roommateRepository,
                choreRepository: container.choreRepository,
                guestRepository: container.guestRepository
            )
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Üst karşılama & Ev halkı kartı
                    headerSection

                    // Hızlı istatistikler
                    statsOverviewSection

                    // Acil veya Bugün yapılacak görevler
                    if !viewModel.urgentChores.isEmpty {
                        urgentChoresSection
                    }

                    // Görev Döngüsü / Kimin Sırası
                    choresTurnSection

                    // Yaklaşan Misafirler
                    upcomingGuestsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppTheme.background)
            .navigationTitle("HighFive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(AppTheme.primary)
                        Text("HighFive")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        GlassCardView(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Öğrenci Evi")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Günün Özeti")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Text(Date().shortDateText)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.primary.opacity(0.1))
                        .foregroundColor(AppTheme.primary)
                        .cornerRadius(12)
                }

                Divider()

                HStack(spacing: 12) {
                    Text("Ev Halkı:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.roommates) { roommate in
                                HStack(spacing: 6) {
                                    AvatarBadgeView(
                                        emoji: roommate.avatarEmoji,
                                        initials: roommate.initials,
                                        colorHex: roommate.avatarColorHex,
                                        size: 26
                                    )
                                    Text(roommate.displayName)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: roommate.avatarColorHex).opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
    }

    private var statsOverviewSection: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Acil Görev",
                count: "\(viewModel.urgentChores.count)",
                icon: "exclamationmark.circle.fill",
                color: viewModel.urgentChores.isEmpty ? AppTheme.success : AppTheme.danger
            )
            statCard(
                title: "Aktif İş",
                count: "\(viewModel.chores.count)",
                icon: "checklist",
                color: AppTheme.primary
            )
            statCard(
                title: "Misafir",
                count: "\(viewModel.activeVisits.count + viewModel.upcomingVisits.count)",
                icon: "person.2.fill",
                color: AppTheme.secondary
            )
        }
    }

    private func statCard(title: String, count: String, icon: String, color: Color) -> some View {
        GlassCardView(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(color)
                    Spacer()
                }
                Text(count)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var urgentChoresSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Acil / Bugün Yapılacaklar", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundColor(AppTheme.danger)
                Spacer()
            }

            ForEach(viewModel.urgentChores) { chore in
                GlassCardView(padding: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: chore.category.iconName)
                            .font(.title3)
                            .foregroundColor(Color(hex: chore.category.colorHex))
                            .frame(width: 36, height: 36)
                            .background(Color(hex: chore.category.colorHex).opacity(0.15))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(chore.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            HStack(spacing: 6) {
                                if let assignee = viewModel.roommate(for: chore.currentAssigneeId) {
                                    Text("Sıra: \(assignee.displayName)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color(hex: assignee.avatarColorHex))
                                }
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(chore.dueDate.relativeFormattedText)
                                    .font(.caption)
                                    .foregroundColor(chore.isOverdue ? AppTheme.danger : .secondary)
                            }
                        }

                        Spacer()

                        Button {
                            Task {
                                await viewModel.completeChore(chore)
                            }
                        } label: {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppTheme.success)
                        }
                    }
                }
            }
        }
    }

    private var choresTurnSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ev İşleri & Sıradaki Kişi")
                    .font(.headline)
                Spacer()
            }

            ForEach(viewModel.upcomingChores) { chore in
                GlassCardView(padding: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: chore.category.iconName)
                            .foregroundColor(Color(hex: chore.category.colorHex))
                            .frame(width: 32, height: 32)
                            .background(Color(hex: chore.category.colorHex).opacity(0.12))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(chore.title)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            HStack(spacing: 4) {
                                Image(systemName: chore.assignmentType.iconName)
                                    .font(.system(size: 9))
                                    .foregroundColor(chore.assignmentType == .dedicated ? AppTheme.secondary : AppTheme.primary)
                                Text("\(chore.assignmentType.rawValue) • \(chore.frequency.rawValue)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if let assignee = viewModel.roommate(for: chore.currentAssigneeId) {
                            HStack(spacing: 6) {
                                AvatarBadgeView(
                                    emoji: assignee.avatarEmoji,
                                    initials: assignee.initials,
                                    colorHex: assignee.avatarColorHex,
                                    size: 24
                                )
                                Text(assignee.displayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(hex: assignee.avatarColorHex))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: assignee.avatarColorHex).opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }

    private var upcomingGuestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Yaklaşan Misafirler")
                    .font(.headline)
                Spacer()
            }

            if viewModel.upcomingVisits.isEmpty && viewModel.activeVisits.isEmpty {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: "Misafir Planı Yok",
                    message: "Şu an planlanmış bir misafir ziyareti bulunmuyor."
                )
            } else {
                ForEach(viewModel.activeVisits + viewModel.upcomingVisits) { visit in
                    GlassCardView(padding: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: visit.isOvernight ? "moon.stars.fill" : "sun.max.fill")
                                .foregroundColor(AppTheme.secondary)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(visit.guestName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    if visit.guestCount > 1 {
                                        Text("(\(visit.guestCount) kişi)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if let host = viewModel.roommate(for: visit.hostRoommateId) {
                                    Text("Davet Eden: \(host.displayName)")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: host.avatarColorHex))
                                }

                                Text("\(visit.startDate.shortDateText) - \(visit.endDate.shortDateText) (\(visit.stayLocation))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            StatusPillView(
                                text: visit.isCurrentlyActive ? "Evde" : visit.startDate.relativeFormattedText,
                                color: visit.isCurrentlyActive ? AppTheme.success : AppTheme.primary
                            )
                        }
                    }
                }
            }
        }
    }
}

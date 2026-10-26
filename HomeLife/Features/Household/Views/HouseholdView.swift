import SwiftUI

public struct HouseholdView: View {
    @StateObject private var viewModel: HouseholdViewModel

    public init(container: DependencyContainer) {
        _viewModel = StateObject(
            wrappedValue: HouseholdViewModel(
                roommateRepository: container.roommateRepository,
                choreRepository: container.choreRepository
            )
        )
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Ev Bilgisi Kartı
                    houseInfoCard

                    // Ev Arkadaşları Başlığı
                    HStack {
                        Text("Ev Halkı (\(viewModel.roommates.count) Kişi)")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.top, 4)

                    // Arkadaş Kartları
                    ForEach(viewModel.roommates) { roommate in
                        roommateCard(for: roommate)
                    }

                    // Gelecek Özellikler (Modüler Genişletme) Tanıtımı
                    upcomingFeaturesCard
                }
                .padding(16)
            }
            .background(AppTheme.background)
            .navigationTitle("Ev Halkı & Yönetim")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isShowingAddSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddSheet) {
                AddRoommateSheet { name, nickname, emoji, color, phone, room in
                    Task {
                        await viewModel.addRoommate(
                            name: name,
                            nickname: nickname,
                            avatarEmoji: emoji,
                            colorHex: color,
                            phoneNumber: phone,
                            roomName: room
                        )
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

    private var houseInfoCard: some View {
        GlassCardView(padding: 16) {
            HStack(spacing: 14) {
                Image(systemName: "house.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Bizim Öğrenci Evi")
                        .font(.headline)
                    Text("Adil görev paylaşımı ve misafir takvimi aktif")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }

    private func roommateCard(for roommate: Roommate) -> some View {
        GlassCardView(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    AvatarBadgeView(
                        emoji: roommate.avatarEmoji,
                        initials: roommate.initials,
                        colorHex: roommate.avatarColorHex,
                        size: 44
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(roommate.name)
                            .font(.headline)

                        if let room = roommate.roomName {
                            Text(room)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Menu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteRoommate(roommate)
                            }
                        } label: {
                            Label("Kişiyi Kaldır", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                HStack(spacing: 16) {
                    let currentTurns = viewModel.currentTurnChoreCount(for: roommate.id)
                    let totalAssigned = viewModel.activeChoreCount(for: roommate.id)

                    HStack(spacing: 4) {
                        Text("Şu Anki Sırası:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(currentTurns) Görev")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(currentTurns > 0 ? AppTheme.warning : AppTheme.success)
                    }

                    HStack(spacing: 4) {
                        Text("Dahil Olduğu:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(totalAssigned) Görev")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    Spacer()
                }

                if let phone = roommate.phoneNumber, !phone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.caption2)
                            .foregroundColor(AppTheme.primary)
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var upcomingFeaturesCard: some View {
        GlassCardView(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Yakında Eklenecek Modüller", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primary)

                Text("MVVM ve Repository mimarimiz sayesinde aşağıdaki özellikler kolayca entegre edilebilir:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(AppTheme.success)
                        Text("Ortak Harcama & Masraf Paylaşımı (Kim kime borçlu?)")
                            .font(.caption2)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "cart")
                            .foregroundColor(AppTheme.warning)
                        Text("Ortak Alışveriş & Biten Malzeme Listesi")
                            .font(.caption2)
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "bell")
                            .foregroundColor(AppTheme.secondary)
                        Text("Ev İlan Panosu & Wifi Şifresi / Ev Kuralları")
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(.top, 8)
    }
}

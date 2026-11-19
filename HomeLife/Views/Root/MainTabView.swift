import SwiftUI

public struct MainTabView: View {
    @EnvironmentObject private var container: DependencyContainer
    @State private var selectedTab: TabItem = .dashboard

    public enum TabItem: Hashable {
        case dashboard
        case chores
        case guests
        case pantry
        case household
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(container: container)
                .tabItem {
                    Label("Özet", systemImage: "house.fill")
                }
                .tag(TabItem.dashboard)

            ChoresView(container: container)
                .tabItem {
                    Label("İş Sırası", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(TabItem.chores)

            GuestCalendarView(container: container)
                .tabItem {
                    Label("Misafirler", systemImage: "calendar")
                }
                .tag(TabItem.guests)

            PantryView(container: container)
                .tabItem {
                    Label("Mutfak", systemImage: "refrigerator.fill")
                }
                .tag(TabItem.pantry)

            HouseholdView(container: container)
                .tabItem {
                    Label("Ev Halkı", systemImage: "person.2.fill")
                }
                .tag(TabItem.household)
        }
        .tint(AppTheme.primary)
        .safeAreaInset(edge: .top, spacing: 0) {
            if let message = container.sessionErrorMessage {
                ErrorBannerView(
                    message: message,
                    onRetry: {
                        Task { await container.retryBootstrap() }
                    },
                    onDismiss: {
                        container.clearSessionError()
                    }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: container.sessionErrorMessage)
    }
}

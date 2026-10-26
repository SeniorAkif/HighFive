import SwiftUI

public struct MainTabView: View {
    @EnvironmentObject private var container: DependencyContainer
    @State private var selectedTab: TabItem = .dashboard

    public enum TabItem: Hashable {
        case dashboard
        case chores
        case guests
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

            HouseholdView(container: container)
                .tabItem {
                    Label("Ev Halkı", systemImage: "person.2.fill")
                }
                .tag(TabItem.household)
        }
        .tint(AppTheme.primary)
    }
}

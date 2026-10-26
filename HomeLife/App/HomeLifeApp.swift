import SwiftUI

@main
struct HomeLifeApp: App {
    @StateObject private var container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(container)
        }
    }
}

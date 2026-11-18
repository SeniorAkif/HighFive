import SwiftUI
import FirebaseCore

@main
struct HighFiveApp: App {
    @StateObject private var container: DependencyContainer
    @StateObject private var languageManager = LanguageManager.shared

    init() {
        FirebaseApp.configure()
        _container = StateObject(wrappedValue: DependencyContainer.live())
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(container)
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.locale)
                .task {
                    // Arka planda anonim giriş + aktif ev kurulumu
                    await container.bootstrap()
                }
        }
    }
}

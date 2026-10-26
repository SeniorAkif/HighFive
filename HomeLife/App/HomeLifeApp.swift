import SwiftUI

@main
struct HighFiveApp: App {
    @StateObject private var container = DependencyContainer()
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(container)
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.locale)
        }
    }
}

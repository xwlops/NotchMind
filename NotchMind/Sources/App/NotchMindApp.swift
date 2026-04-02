import SwiftUI

@main
struct NotchMindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.appState)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            NotchMindCommands(appState: appDelegate.appState)
        }

        MenuBarExtra("NotchMind", systemImage: "cpu") {
            MenuBarView(appState: appDelegate.appState)
        }
        #if available(macOS 13.0, *)
        .menuBarExtraStyle(.menu)
        #endif
    }
}
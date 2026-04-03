import SwiftUI

@main
struct NotchMindApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @SceneBuilder
    var body: some Scene {
        WindowGroup {
            NotchPanelView(startExpanded: true)
                .environmentObject(appDelegate.appState)
                .frame(minWidth: 1100, minHeight: 760)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            NotchMindCommands(appState: appDelegate.appState)
        }

        if #available(macOS 13.0, *) {
            MenuBarExtra("NotchMind", systemImage: "cpu") {
                MenuBarView(appState: appDelegate.appState)
            }
            .menuBarExtraStyle(.menu)
        }
    }
}

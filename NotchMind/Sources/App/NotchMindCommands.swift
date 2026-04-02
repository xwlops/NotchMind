import SwiftUI

struct NotchMindCommands: Commands {
    let appState: AppState

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("About NotchMind") {
                NSApplication.shared.orderFrontStandardAboutPanel(
                    options: [
                        .applicationName: "NotchMind",
                        .applicationVersion: "1.0",
                        .credits: NSAttributedString(string: "AI Coding Assistant Control Center")
                    ]
                )
            }
        }

        CommandGroup(after: .newItem) {
            Divider()

            Button("Open Terminal") {
                appState.openTerminal()
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])

            Button("Refresh Tools") {
                appState.aiMonitorService.forceRefresh()
            }
            .keyboardShortcut("r", modifiers: .command)
        }

        CommandGroup(replacing: .windowList) {
            Button("Show Main Window") {
                NSApplication.shared.keyWindow?.makeKeyAndOrderFront(nil)
            }
            .keyboardShortcut("1", modifiers: .command)
        }
    }
}
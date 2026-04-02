import Foundation
import AppKit

/// Handles terminal integration and navigation
final class TerminalIntegrator {
    private let terminalBundleId = "com.apple.Terminal"
    private let iTermBundleId = "com.googlecode.iterm2"

    func openTerminal() {
        openApp(bundleId: terminalBundleId)
    }

    func openTerminal(with tool: AITool) {
        openTerminal()
        // In a full implementation, send the tool's working directory/context
    }

    func openITerm() {
        openApp(bundleId: iTermBundleId)
    }

    func openITerm(with tool: AITool) {
        openITerm()
    }

    func openTerminalInDirectory(_ directory: String) {
        guard let url = URL(string: "file://\(directory)") else { return }

        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == iTermBundleId }) {
            // Open in iTerm if available
            NSWorkspace.shared.open(url)
        } else {
            // Open in Terminal
            NSWorkspace.shared.open(url)
        }
    }

    private func openApp(bundleId: String) {
        // First, try to activate if already running
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) {
            app.activate(options: .activateIgnoringOtherApps)
        } else {
            // Find the application URL and use the modern API
            let urls = NSWorkspace.shared.urlsForApplications(withBundleIdentifier: bundleId)
            if let appUrl = urls.first {
                var config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.openApplication(at: appUrl, configuration: config) { runningApp, error in
                    if let error = error {
                        print("Failed to launch \(bundleId): \(error)")
                    }
                }
            } else {
                // As a fallback, we can try launching by URL with just the bundle identifier
                // Though ideally the urlsForApplications call should have found the app
                print("Could not find application with bundle identifier: \(bundleId)")
            }
        }
    }
}
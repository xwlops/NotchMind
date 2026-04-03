import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var cancellables = Set<AnyCancellable>()

    // Notch-related properties
    private var notchPanelController: NotchPanelController?
    private let keyboardShortcutManager = KeyboardShortcutManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBarApp()
        setupNotchPanelController()
        setupKeyboardShortcuts()
        startServices()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cleanupResources()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        cleanupResources()
        return .terminateNow
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    private func setupMenuBarApp() {
        // Menu bar app is handled via SwiftUI MenuBarExtra
    }

    private func setupNotchPanelController() {
        notchPanelController = NotchPanelController()
        keyboardShortcutManager.setNotchPanelController(notchPanelController)
    }

    private func setupKeyboardShortcuts() {
        // Listen for shortcut state changes
        keyboardShortcutManager.$notchPanelVisible
            .sink { [weak self] isVisible in
                if !isVisible {
                    self?.notchPanelController?.hidePanel()
                }
            }
            .store(in: &cancellables)
    }

    private func startServices() {
        // Start AI tool monitoring service
        appState.aiMonitorService.startMonitoring()

        // Start performance monitoring
        appState.performanceMonitor.startMonitoring()
    }

    private func stopServices() {
        appState.aiMonitorService.stopMonitoring()
        appState.performanceMonitor.stopMonitoring()
    }

    private func cleanupResources() {
        stopServices()
        keyboardShortcutManager.setNotchPanelController(nil)
        notchPanelController?.teardown()
        notchPanelController = nil
        cancellables.removeAll()
    }
}

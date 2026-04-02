//
//  NotchMind - Application Delegate
//  AppDelegate.swift
//

import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var notchPanelController: NotchPanelController?
    private var aiToolMonitor: AIToolMonitorService?
    private var permissionManager: PermissionManagerService?
    private var cancellables = Set<AnyCancellable>()

    // Memory optimization properties
    private var memoryPressureObserver: Any?
    private let monitorQueue = DispatchQueue(label: "com.notchmind.monitor", qos: .utility)

    // MARK: - Application Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupServices()
        setupStatusBarItem()
        setupNotchPanel()
        startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopMonitoring()
        cleanupResources()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        cleanupResources()
        return .terminateNow
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        setupMemoryWarningHandler()
    }

    // MARK: - Setup

    private func setupServices() {
        permissionManager = PermissionManagerService()
        aiToolMonitor = AIToolMonitorService(permissionManager: permissionManager!)
    }

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "NotchMind")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }

        setupStatusBarMenu()
    }

    private func setupMemoryWarningHandler() {
        // Register for memory pressure events
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let callback: CFNotificationCallback = { center, observer, name, object, userInfo in
            print("MemoryWarning received")
            // Handle memory pressure
            DispatchQueue.main.async {
                // Reduce memory footprint by clearing caches or stopping non-essential work
            }
        }

        CFNotificationCenterAddObserver(center,
                                     nil,
                                     callback,
                                     "memorypressure",
                                     nil,
                                     .deliverImmediately)
    }

    private func setupStatusBarMenu() {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "Show Notch Panel", action: #selector(showNotchPanel), keyEquivalent: "n"))
        menu.addItem(NSMenuItem.separator())

        let toolsMenu = NSMenu()
        let toolsItem = NSMenuItem(title: "AI Tools", action: nil, keyEquivalent: "")
        toolsItem.submenu = toolsMenu

        for tool in AIToolType.allCases {
            let toolItem = NSMenuItem(title: tool.displayName, action: #selector(toolMenuItemClicked(_:)), keyEquivalent: "")
            toolItem.representedObject = tool
            toolsMenu.addItem(toolItem)
        }

        menu.addItem(toolsItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit NotchMind", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func setupNotchPanel() {
        notchPanelController = NotchPanelController()
    }

    private func startMonitoring() {
        aiToolMonitor?.startMonitoring()
    }

    private func stopMonitoring() {
        aiToolMonitor?.stopMonitoring()
    }

    private func cleanupResources() {
        // Stop monitoring first to cancel all ongoing tasks
        aiToolMonitor?.stopMonitoring()

        // Clear cancellables
        cancellables.removeAll()

        // Nil out services to ensure they're deallocated
        aiToolMonitor = nil
        permissionManager = nil

        // Close and nil out the panel
        notchPanelController = nil

        // Remove status bar item
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    // MARK: - Actions

    @objc private func statusBarButtonClicked() {
        showNotchPanel()
    }

    @objc private func showNotchPanel() {
        notchPanelController?.showPanel()
    }

    @objc private func toolMenuItemClicked(_ sender: NSMenuItem) {
        guard let tool = sender.representedObject as? AIToolType else { return }
        aiToolMonitor?.checkToolStatus(tool)
    }

    @objc private func showPreferences() {
        // Preferences window implementation
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
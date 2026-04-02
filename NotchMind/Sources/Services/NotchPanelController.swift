import AppKit
import SwiftUI

/// Controller for managing the notch panel UI
class NotchPanelController: NSObject {

    private var panel: NSPanel?
    private var hostingController: NSViewController?
    private var notchPanelView: NotchPanelView?

    override init() {
        super.init()
    }

    func showPanel() {
        // Determine if we need to create the panel or just show it
        if panel == nil {
            createPanel()
        }

        // Show the panel
        if let panel = panel {
            panel.orderFrontRegardless()
            panel.makeKeyAndOrderFront(nil)

            // Position panel near the notch area
            positionPanelNearNotch(panel)
        }
    }

    private func createPanel() {
        // Determine screen with notch (main screen for now)
        guard let mainScreen = NSScreen.main else { return }

        // Calculate initial size and safe area considering notch
        let initialSize = CGSize(width: 300, height: 400)

        // Create the panel
        let panel = NSPanel(
            contentRect: CGRect(origin: mainScreen.frame.origin, size: initialSize),
            styleMask: [.nonactivatingPanel, .closable, .resizable, .titled],
            backing: .buffered,
            defer: false
        )

        panel.title = "NotchMind"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = true
        panel.backgroundColor = NSColor.windowBackgroundColor

        // Safely get the app delegate to access the shared app state
        guard let appDelegate = NSApp.delegate as? AppDelegate else {
            print("Failed to get app delegate")
            return
        }

        // Create the NotchPanelView with the app state from the delegate
        let contentView = NotchPanelView().environmentObject(appDelegate.appState)
        let hostingController = NSHostingController(rootView: contentView)

        panel.contentViewController = hostingController
        self.hostingController = hostingController
        self.panel = panel
    }

    private func positionPanelNearNotch(_ panel: NSPanel) {
        guard let mainScreen = NSScreen.main else { return }

        let notchRect = NotchGeometry.getNotchRect(for: mainScreen)

        if !notchRect.equalTo(CGRect.zero) {
            // Position panel below the notch
            let panelFrame = panel.frame
            let newX = notchRect.midX - (panelFrame.width / 2)
            let newY = mainScreen.frame.maxY - notchRect.height - panelFrame.height - 20 // 20pt margin

            panel.setFrame(CGRect(x: newX, y: newY, width: panelFrame.width, height: panelFrame.height), display: true)
        } else {
            // If no notch, center on screen
            let screenRect = mainScreen.visibleFrame
            let panelFrame = panel.frame

            let centerX = screenRect.midX - (panelFrame.width / 2)
            let centerY = screenRect.midY - (panelFrame.height / 2)

            panel.setFrame(
                CGRect(
                    x: centerX,
                    y: centerY,
                    width: panelFrame.width,
                    height: panelFrame.height
                ),
                display: true
            )
        }
    }

    func hidePanel() {
        panel?.orderOut(nil)
    }

    deinit {
        panel?.close()
    }
}
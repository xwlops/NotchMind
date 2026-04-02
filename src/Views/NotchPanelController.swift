//
//  NotchMind - Notch Panel Controller
//  NotchPanelController.swift
//

import AppKit
import Combine

/// Controller for the Notch Panel UI
final class NotchPanelController: ObservableObject {

    // MARK: - Properties

    private var panel: NSPanel?
    private var contentViewController: NotchPanelViewController?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupPanel()
    }

    deinit {
        // Ensure panel is properly closed when controller is deallocated
        panel?.close()
        panel = nil
        contentViewController = nil
    }

    // MARK: - Public Methods

    func showPanel() {
        guard let panel = panel else { return }

        if !panel.isVisible {
            positionPanel()
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func hidePanel() {
        panel?.orderOut(nil)
    }

    func togglePanel() {
        if panel?.isVisible == true {
            hidePanel()
        } else {
            showPanel()
        }
    }

    // MARK: - Private Methods

    private func setupPanel() {
        // Create borderless panel that floats above other windows
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false

        // Setup content view controller
        contentViewController = NotchPanelViewController()
        panel.contentViewController = contentViewController

        self.panel = panel
    }

    private func positionPanel() {
        guard let panel = panel,
              let screen = NSScreen.main else { return }

        let screenFrame = screen.frame
        let panelFrame = panel.frame

        // Position at top center (notch area)
        let x = screenFrame.midX - (panelFrame.width / 2)
        let y = screenFrame.maxY - panelFrame.height - 10

        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    deinit {
        panel = nil
    }
}

/// Main view controller for the Notch Panel content
final class NotchPanelViewController: NSViewController {

    // MARK: - Properties

    private var statusView: NotchStatusView?
    private var toolStackView: NSStackView?

    // MARK: - Lifecycle

    override func loadView() {
        // Create transparent container view
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        containerView.wantsLayer = true

        // Apply retro-futuristic styling
        containerView.layer?.backgroundColor = NSColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 0.95).cgColor
        containerView.layer?.cornerRadius = 16
        containerView.layer?.borderWidth = 1
        containerView.layer?.borderColor = NSColor(hex: "#74c7ec")?.withAlphaComponent(0.3).cgColor

        self.view = containerView

        setupUI()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - UI Setup

    private func setupUI() {
        setupHeader()
        setupToolStatusView()
        setupActionButtons()
    }

    private func setupHeader() {
        let headerLabel = NSTextField(labelWithString: "NotchMind")
        headerLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        headerLabel.textColor = NSColor(hex: "#cdd6f4")
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(headerLabel)

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupToolStatusView() {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.spacing = 16
        stackView.alignment = .centerY
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Create status indicators for each tool
        for tool in AIToolType.allCases {
            let toolView = ToolStatusIndicatorView(toolType: tool)
            stackView.addArrangedSubview(toolView)
        }

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        self.toolStackView = stackView
    }

    private func setupActionButtons() {
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let terminalButton = createActionButton(title: "Terminal", icon: "terminal")
        let prefsButton = createActionButton(title: "Settings", icon: "gearshape")

        buttonStack.addArrangedSubview(terminalButton)
        buttonStack.addArrangedSubview(prefsButton)

        view.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            buttonStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16),
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func createActionButton(title: String, icon: String) -> NSButton {
        let button = NSButton()
        button.title = title
        button.image = NSImage(systemSymbolName: icon, accessibilityDescription: title)
        button.imagePosition = .imageLeading
        button.bezelStyle = .rounded
        button.isBordered = true

        button.contentTintColor = NSColor(hex: "#74c7ec")

        return button
    }
}

// MARK: - Supporting Views

/// View showing status indicator for a single tool
final class ToolStatusIndicatorView: NSView {

    private let toolType: AIToolType
    private var statusDot: NSView?

    init(toolType: AIToolType) {
        self.toolType = toolType
        super.init(frame: NSRect(x: 0, y: 0, width: 60, height: 50))
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Status dot
        let dot = NSView(frame: NSRect(x: 20, y: 35, width: 20, height: 20))
        dot.wantsLayer = true
        dot.layer?.cornerRadius = 10
        dot.layer?.backgroundColor = NSColor(hex: "#6c7086")?.cgColor

        // Add glow effect
        dot.layer?.shadowColor = NSColor(hex: "#50fa7b")?.cgColor
        dot.layer?.shadowRadius = 4
        dot.layer?.shadowOpacity = 0.5
        dot.layer?.shadowOffset = .zero

        addSubview(dot)
        self.statusDot = dot

        // Tool label
        let label = NSTextField(labelWithString: toolType.displayName)
        label.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        label.textColor = NSColor(hex: "#6c7086")
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: dot.bottomAnchor, constant: 4),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

    func updateStatus(_ status: ToolStatus) {
        let color: NSColor

        switch status {
        case .online:
            color = NSColor(hex: "#50fa7b") ?? .green
        case .busy:
            color = NSColor(hex: "#f1fa8c") ?? .yellow
        case .offline:
            color = NSColor(hex: "#ff5555") ?? .red
        case .requestingPermission:
            color = NSColor(hex: "#bd93f9") ?? .purple
        }

        statusDot?.layer?.backgroundColor = color.cgColor
        statusDot?.layer?.shadowColor = color.cgColor
    }
}

/// Compact status view for the notch area
final class NotchStatusView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    // Custom drawing for compact status display
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Background handled by window
    }
}
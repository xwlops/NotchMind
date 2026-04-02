import AppKit
import Carbon

/// Manages global keyboard shortcuts for the NotchMind application
class KeyboardShortcutManager: ObservableObject {
    private var eventMonitor: Any?

    // MARK: - Singleton
    static let shared = KeyboardShortcutManager()

    // MARK: - Published Properties
    @Published var notchPanelVisible = false

    // MARK: - Private Properties
    private weak var notchPanelController: NotchPanelController?

    private init() {
        setupGlobalHotkeys()
    }

    func setNotchPanelController(_ controller: NotchPanelController?) {
        self.notchPanelController = controller
    }

    private func setupGlobalHotkeys() {
        // Register for global hotkey events
        registerHotkey(command: true, shift: true, key: kVK_ANSI_N) { [weak self] in
            self?.toggleNotchPanel()
        }

        registerHotkey(command: true, shift: true, key: kVK_ANSI_B) { [weak self] in
            self?.toggleNotchPanelBackground()
        }

        registerHotkey(command: true, shift: true, key: kVK_ANSI_A) { [weak self] in
            self?.activateAIAgent()
        }

        registerHotkey(keyCode: kVK_Escape) { [weak self] in
            self?.dismissNotchPanel()
        }
    }

    private func registerHotkey(command: Bool = false, shift: Bool = false, control: Bool = false, option: Bool = false, key: Int, handler: @escaping () -> Void) {
        let modifiers = convertModifiers(command: command, shift: shift, control: control, option: option)

        let hotkey = HotKey(keyCombo: KeyCombo(keyCode: key, carbonModifiers: modifiers))
        hotkey.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                handler()

                // Handle the escape key specifically to dismiss panels
                if key == kVK_Escape {
                    self?.notchPanelVisible = false
                } else if command, shift, key == kVK_ANSI_N {
                    self?.notchPanelVisible.toggle()
                }
            }
        }
    }

    private func registerHotkey(keyCode: Int, handler: @escaping () -> Void) {
        let hotkey = HotKey(keyCombo: KeyCombo(keyCode: keyCode, carbonModifiers: 0))
        hotkey.keyDownHandler = { [weak self] in
            DispatchQueue.main.async {
                handler()
            }
        }
    }

    private func convertModifiers(command: Bool, shift: Bool, control: Bool, option: Bool) -> Int {
        var modifiers: Int = 0
        if command { modifiers |= cmdKey
        }
        if shift { modifiers |= shiftKey
        }
        if control { modifiers |= controlKey
        }
        if option { modifiers |= OptionKey
        }
        return modifiers
    }

    // MARK: - Public Methods
    func toggleNotchPanel() {
        if notchPanelVisible {
            dismissNotchPanel()
        } else {
            showNotchPanel()
        }
    }

    func showNotchPanel() {
        notchPanelController?.showPanel()
        notchPanelVisible = true
    }

    func dismissNotchPanel() {
        notchPanelController?.hidePanel()
        notchPanelVisible = false
    }

    private func toggleNotchPanelBackground() {
        // Toggle visibility without focusing
        notchPanelVisible.toggle()
        if notchPanelVisible {
            notchPanelController?.showPanel()
        } else {
            notchPanelController?.hidePanel()
        }
    }

    private func activateAIAgent() {
        // Activate the primary AI agent
        NotificationCenter.default.post(name: Notification.Name("ActivateAIAgent"), object: nil)
    }

    deinit {
        unregisterAllHotkeys()
    }

    private func unregisterAllHotkeys() {
        HotKey.unregisterAll()
    }
}

// MARK: - Helper Structures (These would normally be in separate files)

/// Represents a combination of a key code and modifier keys
struct KeyCombo: Equatable {
    let keyCode: Int
    let carbonModifiers: Int

    var modifiers: NSEvent.ModifierFlags {
        var modifiers: NSEvent.ModifierFlags = []

        if carbonModifiers & cmdKey != 0 { modifiers.insert(.command) }
        if carbonModifiers & optionKey != 0 { modifiers.insert(.option) }
        if carbonModifiers & controlKey != 0 { modifiers.insert(.control) }
        if carbonModifiers & shiftKey != 0 { modifiers.insert(.shift) }

        return modifiers
    }

    init(keyCode: Int, carbonModifiers: Int) {
        self.keyCode = keyCode
        self.carbonModifiers = carbonModifiers
    }
}

/// Handles individual hotkeys
class HotKey {
    static private var hotKeys: [HotKey] = []
    static private var eventTap: CFMachPort?
    static private var runLoopSource: CFRunLoopSource?

    let keyCombo: KeyCombo
    var keyDownHandler: (() -> Void)?

    private var isRegistered = false

    init(keyCombo: KeyCombo) {
        self.keyCombo = keyCombo

        Self.hotKeys.append(self)
        register()
    }

    static func unregisterAll() {
        hotKeys.forEach { $0.unregister() }
        hotKeys.removeAll()

        if let tap = eventTap {
            CFMachPortInvalidate(tap)
            eventTap = nil
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            runLoopSource = nil
        }
    }

    private func register() {
        guard !isRegistered else { return }
        isRegistered = true

        if Self.eventTap == nil {
            setupEventTap()
        }
    }

    private func unregister() {
        isRegistered = false
    }

    private func setupEventTap() {
        let eventMask = (1 << UInt32(kCGKeyDown)) // CGEventMask(rawValue: 1 << CGEventType.keyDown.rawValue)
        let tapLocation = CGEventTapLocation.cghidEventTap

        guard let tap = CGEvent.tapCreate(
            tapLocation,
            .listenOnly,
            .default,
            eventMask,
            { _, _, event in
                return HotKey.handle(events: [event])
            },
            nil
        ) else {
            return
        }

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        Self.eventTap = tap
        Self.runLoopSource = runLoopSource

        CFRunLoopRun()
    }

    private static func handle(events: [CGEvent]) -> CGEvent? {
        for event in events {
            guard event.type == .keyDown else { continue }

            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let modifiers = Int(event.flags.rawValue)

            for hotKey in hotKeys where hotKey.matches(keyCode: keyCode, modifiers: modifiers) {
                hotKey.keyDownHandler?()
                return event
            }
        }

        return nil
    }

    private func matches(keyCode: Int, modifiers: Int) -> Bool {
        guard self.keyCombo.keyCode == keyCode else { return false }

        // Compare modifiers by checking if the required modifiers are pressed
        let requiredModifiers = self.keyCombo.carbonModifiers
        // We only care about matching the specified modifiers, ignoring others
        return (requiredModifiers == 0) ||
               ((modifiers & requiredModifiers) == requiredModifiers)
    }
}
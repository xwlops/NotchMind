import Foundation
import Combine

/// Global application state managed by AppDelegate
final class AppState: ObservableObject {
    // MARK: - Published Properties

    @Published var isMonitoring: Bool = false
    @Published var monitoredTools: [AITool] = []
    @Published var detectedTools: [AITool] = []  // Exposed for view access
    @Published var pendingPermissions: [PermissionRequest] = []
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0

    // MARK: - Notch-related state
    @Published var notchIsExpanded = false
    @Published var currentNotchState: AgentState = .waiting

    // MARK: - Services (lazy init to reduce startup memory)

    let aiMonitorService = AIToolMonitorService()
    let permissionManager = PermissionManager()
    let performanceMonitor = PerformanceMonitor()
    let terminalIntegrator = TerminalIntegrator()

    // Services that can be lazily initialized
    private lazy var agentManager: AgentManager = AgentManager()

    // MARK: - Initialization

    init() {
        setupBindings()
    }

    private func setupBindings() {
        // Bind AI monitor to published tools
        aiMonitorService.$detectedTools
            .receive(on: DispatchQueue.main)
            .assign(to: &$monitoredTools)

        aiMonitorService.$detectedTools
            .receive(on: DispatchQueue.main)
            .assign(to: &$detectedTools)

        aiMonitorService.$isMonitoring
            .receive(on: DispatchQueue.main)
            .assign(to: &$isMonitoring)

        // Bind permission requests
        permissionManager.$pendingRequests
            .receive(on: DispatchQueue.main)
            .assign(to: &$pendingPermissions)

        // Bind performance metrics
        performanceMonitor.$memoryUsage
            .receive(on: DispatchQueue.main)
            .assign(to: &$memoryUsage)

        performanceMonitor.$cpuUsage
            .receive(on: DispatchQueue.main)
            .assign(to: &$cpuUsage)

        // Update notch state when tools change
        aiMonitorService.$detectedTools
            .sink { [weak self] _ in
                self?.updateCurrentNotchState()
            }
            .store(in: &cancellables)
    }

    private func updateCurrentNotchState() {
        let activeTools = monitoredTools.filter { $0.isActive }

        if activeTools.contains(where: { $0.status == .error }) {
            currentNotchState = .error
        } else if activeTools.contains(where: { $0.status == .running }) {
            currentNotchState = .running
        } else if activeTools.contains(where: { $0.status == .waiting }) {
            currentNotchState = .waiting
        } else if activeTools.contains(where: { $0.status == .disabled }) {
            currentNotchState = .permissionRequest
        } else {
            currentNotchState = .waiting
        }
    }

    // MARK: - Actions

    func approvePermission(_ request: PermissionRequest) {
        permissionManager.approve(request)
    }

    func denyPermission(_ request: PermissionRequest) {
        permissionManager.deny(request)
    }

    func openTerminal() {
        terminalIntegrator.openTerminal()
    }

    func openTerminalWithContext(for tool: AITool) {
        terminalIntegrator.openTerminal(with: tool)
    }

    private var cancellables = Set<AnyCancellable>()
}
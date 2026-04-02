import SwiftUI
import Combine

/// ViewModel for the main tool list
final class ToolListViewModel: ObservableObject {
    @Published var tools: [AITool] = []
    @Published var isRefreshing: Bool = false

    private var appState: AppState
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        setupBindings()
    }

    private func setupBindings() {
        appState.$monitoredTools
            .receive(on: DispatchQueue.main)
            .assign(to: &$tools)
    }

    func refresh() {
        isRefreshing = true
        appState.aiMonitorService.forceRefresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isRefreshing = false
        }
    }

    func openTerminal(for tool: AITool) {
        appState.openTerminalWithContext(for: tool)
    }
}

/// ViewModel for permission management
final class PermissionViewModel: ObservableObject {
    @Published var pendingRequests: [PermissionRequest] = []

    private var appState: AppState
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        setupBindings()
    }

    private func setupBindings() {
        appState.$pendingPermissions
            .receive(on: DispatchQueue.main)
            .assign(to: &$pendingRequests)
    }

    func approve(_ request: PermissionRequest) {
        appState.approvePermission(request)
    }

    func deny(_ request: PermissionRequest) {
        appState.denyPermission(request)
    }
}

/// ViewModel for performance metrics
final class PerformanceViewModel: ObservableObject {
    @Published var memoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0

    private var appState: AppState
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        setupBindings()
    }

    private func setupBindings() {
        appState.$memoryUsage
            .receive(on: DispatchQueue.main)
            .assign(to: &$memoryUsage)

        appState.$cpuUsage
            .receive(on: DispatchQueue.main)
            .assign(to: &$cpuUsage)
    }

    var memoryUsageText: String {
        String(format: "%.1f MB", memoryUsage)
    }

    var cpuUsageText: String {
        String(format: "%.1f%%", cpuUsage)
    }

    var isMemoryHealthy: Bool {
        memoryUsage < 50.0 // Under 50MB target
    }
}
import Foundation
import Combine
import AppKit

/// Service responsible for monitoring AI tool processes and detecting their status
final class AIToolMonitorService: ObservableObject {
    @Published var detectedTools: [AITool] = []
    @Published var isMonitoring: Bool = false
    @Published var lastScanTime: Date?

    // Reference to agent manager for protocol compatibility - lazy init
    private var agentManager: AgentManager?

    private var monitorTimer: Timer?
    private let scanInterval: TimeInterval = 2.0
    private var cancellables = Set<AnyCancellable>()

    // Tool identifiers and process names to monitor
    private let toolProcesses: [(name: String, type: AITool.ToolType)] = [
        ("claude", .claudeCode),
        ("codex", .codex),
        ("gemini", .geminiCLI),
        ("cursor", .cursor),
        ("opencode", .openCode),
        ("droid", .droid)
    ]

    init(agentManager: AgentManager? = nil) {
        self.agentManager = agentManager
        initializeTools()
    }

    // Lazy getter for AgentManager
    private func getAgentManager() -> AgentManager {
        if let manager = agentManager {
            return manager
        }
        let newManager = AgentManager()
        agentManager = newManager
        return newManager
    }

    private func initializeTools() {
        detectedTools = toolProcesses.map { tool in
            AITool(name: tool.name, type: tool.type, status: .idle, isActive: false)
        }
    }

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        lastScanTime = Date()

        // Initial scan
        scanForRunningTools()

        // Setup periodic scanning
        monitorTimer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] _ in
            self?.scanForRunningTools()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func scanForRunningTools() {
        let runningApps = NSWorkspace.shared.runningApplications
        let activeBundleIds = Set(runningApps.compactMap { $0.bundleIdentifier })

        var updatedTools: [AITool] = []

        for toolInfo in toolProcesses {
            let isActive = activeBundleIds.contains { $0.lowercased().contains(toolInfo.name.lowercased()) }
            let existingTool = detectedTools.first { $0.type == toolInfo.type }

            var tool = existingTool ?? AITool(name: toolInfo.name, type: toolInfo.type)
            tool.isActive = isActive
            tool.status = isActive ? .running : .idle
            tool.lastActivity = isActive ? Date() : tool.lastActivity

            updatedTools.append(tool)
        }

        DispatchQueue.main.async {
            self.detectedTools = updatedTools
            self.lastScanTime = Date()
        }
    }

    func forceRefresh() {
        scanForRunningTools()
    }

    /// Convert an AITool to its corresponding AgentProtocol implementation
    func getAgent(for tool: AITool) -> AgentProtocol? {
        return getAgentManager().getAgent(withId: tool.id.uuidString)
    }

    /// Register a new agent with the monitor service
    func registerAgent(_ agent: AgentProtocol) {
        getAgentManager().registerAgent(agent)

        // Update the detected tools list to include the new agent
        if !detectedTools.contains(where: { $0.id == agent.id }) {
            let newTool = AITool(
                id: agent.id,
                name: agent.name,
                type: agent.type,
                status: agent.status,
                isActive: agent.isActive
            )
            detectedTools.append(newTool)
        }
    }
}
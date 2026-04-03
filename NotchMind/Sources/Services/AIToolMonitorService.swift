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
    private let scanInterval: TimeInterval = 10.0
    private var cancellables = Set<AnyCancellable>()
    private var activeTasks = Set<Task<Void, Never>>()
    private var processCache: [String: Bool] = [:]
    private let cacheQueue = DispatchQueue(label: "com.notchmind.process-cache", attributes: .concurrent)
    private let maxCacheSize = 50

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
        checkAllToolsStatus()

        // Setup periodic scanning
        monitorTimer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }

            // Avoid overlapping scans that can increase memory and CPU pressure.
            if !self.activeTasks.isEmpty {
                return
            }

            self.checkAllToolsStatus()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        monitorTimer?.invalidate()
        monitorTimer = nil

        for task in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        clearCache()
    }

    private func checkAllToolsStatus() {
        let task = Task { @MainActor [weak self] in
            guard let self else { return }

            let runningApps = NSWorkspace.shared.runningApplications
            let activeBundleIds = Set(runningApps.compactMap { $0.bundleIdentifier?.lowercased() })
            var updatedTools: [AITool] = []

            for toolInfo in self.toolProcesses {
                if Task.isCancelled {
                    return
                }

                let isActive = self.isProcessRunning(toolName: toolInfo.name, activeBundleIds: activeBundleIds, runningApps: runningApps)
                let existingTool = self.detectedTools.first { $0.type == toolInfo.type }

                var tool = existingTool ?? AITool(name: toolInfo.name, type: toolInfo.type)
                tool.isActive = isActive
                tool.status = isActive ? .running : .idle
                tool.lastActivity = isActive ? Date() : tool.lastActivity
                updatedTools.append(tool)
            }

            self.detectedTools = updatedTools
            self.lastScanTime = Date()
        }

        activeTasks.insert(task)

        Task { @MainActor [weak self] in
            _ = await task.result
            self?.activeTasks.remove(task)
        }
    }

    private func isProcessRunning(
        toolName: String,
        activeBundleIds: Set<String>,
        runningApps: [NSRunningApplication]
    ) -> Bool {
        if let cached = cacheQueue.sync(execute: { processCache[toolName] }) {
            return cached
        }

        let loweredToolName = toolName.lowercased()

        if activeBundleIds.contains(where: { $0.contains(loweredToolName) }) {
            updateProcessCache(toolName: toolName, isRunning: true)
            return true
        }

        let isRunning = runningApps.contains { app in
            app.localizedName?.lowercased().contains(loweredToolName) ?? false
        }

        updateProcessCache(toolName: toolName, isRunning: isRunning)
        return isRunning
    }

    private func updateProcessCache(toolName: String, isRunning: Bool) {
        cacheQueue.async(flags: .barrier) {
            if self.processCache.count >= self.maxCacheSize {
                self.processCache.removeAll()
            }
            self.processCache[toolName] = isRunning
        }
    }

    private func clearCache() {
        cacheQueue.async(flags: .barrier) {
            self.processCache.removeAll()
        }
    }

    func forceRefresh() {
        checkAllToolsStatus()
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

    deinit {
        monitorTimer?.invalidate()
    }
}

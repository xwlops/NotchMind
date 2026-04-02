import Foundation
import Combine

/// Main facade for AI tool management and protocol compliance
/// Provides unified access to all AI tool functionality
class AIResourceManager: ObservableObject {

    // Singleton instance
    static let shared = AIResourceManager()

    @Published var monitorService: AIToolMonitorService
    @Published var agentManager: AgentManager

    private init() {
        // Initialize with shared agent manager
        self.agentManager = AgentManager()
        self.monitorService = AIToolMonitorService(agentManager: agentManager)
    }

    /// Start the monitoring service
    func startMonitoring() {
        monitorService.startMonitoring()
    }

    /// Stop the monitoring service
    func stopMonitoring() {
        monitorService.stopMonitoring()
    }

    /// Register a new agent with both the agent manager and monitor service
    func registerAgent(_ agent: AgentProtocol) {
        agentManager.registerAgent(agent)
        monitorService.registerAgent(agent)
    }

    /// Get an agent by its tool type
    func getAgent(for type: AITool.ToolType) -> AgentProtocol? {
        // Find in agent manager by matching type
        for agent in agentManager.getAllAgents() {
            if agent.type == type {
                return agent
            }
        }

        // If not found, return nil
        return nil
    }

    /// Get status of all registered agents
    func getAllAgentStatus() -> [(name: String, type: AITool.ToolType, status: AITool.ToolStatus, isActive: Bool)] {
        return agentManager.getAllAgents().map { agent in
            (name: agent.name, type: agent.type, status: agent.status, isActive: agent.isActive)
        }
    }

    /// Start all registered agents
    func startAllAgents() async {
        await agentManager.startAllAgents()
    }

    /// Stop all registered agents
    func stopAllAgents() async {
        await agentManager.stopAllAgents()
    }

    /// Refresh the monitoring service
    func refreshMonitoring() {
        monitorService.forceRefresh()
    }
}
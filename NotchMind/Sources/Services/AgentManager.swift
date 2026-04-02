import Foundation
import Combine
import AppKit

/// Service for managing AI tools that conform to AgentProtocol
final class AgentManager: ObservableObject {
    @Published var agents: [String: AgentProtocol] = [:]

    private var cancellables = Set<AnyCancellable>()

    init() {
        setupNotificationObservers()
    }

    /// Register a new agent
    func registerAgent(_ agent: AgentProtocol) {
        agents[agent.id.uuidString] = agent

        // Subscribe to status updates
        subscribeToAgentUpdates(agent)
    }

    /// Unregister an agent
    func unregisterAgent(withId id: String) {
        agents.removeValue(forKey: id)
    }

    /// Get an agent by ID
    func getAgent(withId id: String) -> AgentProtocol? {
        return agents[id]
    }

    /// Get all registered agents
    func getAllAgents() -> [AgentProtocol] {
        return Array(agents.values)
    }

    /// Subscribe to updates from an agent
    private func subscribeToAgentUpdates(_ agent: AgentProtocol) {
        agent.statusPublisher
            .sink { status in
                // Handle status updates if needed
                print("Agent \(agent.name) status changed to \(status)")
            }
            .store(in: &cancellables)

        agent.activityPublisher
            .sink { isActive in
                // Handle activity updates if needed
                print("Agent \(agent.name) activity changed to \(isActive)")
            }
            .store(in: &cancellables)
    }

    /// Setup observers for system events that might affect agents
    private func setupNotificationObservers() {
        // Add any necessary notification observers
    }

    /// Start all registered agents
    func startAllAgents() async {
        for agent in agents.values {
            try? await agent.start()
        }
    }

    /// Stop all registered agents
    func stopAllAgents() async {
        for agent in agents.values {
            try? await agent.stop()
        }
    }
}
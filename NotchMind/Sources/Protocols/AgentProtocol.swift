import Foundation
import Combine

/// Protocol defining the standard interface for AI tools integration
protocol AgentProtocol {
    /// Unique identifier for the tool
    var id: UUID { get }

    /// Name of the tool
    var name: String { get }

    /// Type of the tool (corresponds to AITool.ToolType)
    var type: AITool.ToolType { get }

    /// Current status of the tool
    var status: AITool.ToolStatus { get }

    /// Whether the tool is currently active
    var isActive: Bool { get }

    /// Last activity timestamp
    var lastActivity: Date? { get }

    /// Publisher for status updates
    var statusPublisher: AnyPublisher<AITool.ToolStatus, Never> { get }

    /// Publisher for activity updates
    var activityPublisher: AnyPublisher<Bool, Never> { get }

    /// Initialize the tool
    func initialize()

    /// Start the tool
    func start() async throws

    /// Stop the tool
    func stop() async throws

    /// Check if the tool is running
    func isRunning() -> Bool

    /// Process input and return output
    func process(input: String) async throws -> String
}
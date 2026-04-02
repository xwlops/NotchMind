import Foundation
import Combine

/// Default implementations for AgentProtocol methods
extension AgentProtocol {
    /// Default implementation that returns false
    func isRunning() -> Bool {
        return isActive && status == .running
    }

    /// Default implementation that throws an error
    func process(input: String) async throws -> String {
        throw NotImplementedError("process(input:) not implemented for \(name)")
    }
}

/// Extension to add convenience methods
extension AgentProtocol {
    /// Helper to check if tool is idle
    var isIdle: Bool {
        return status == .idle
    }

    /// Helper to check if tool has an error
    var hasError: Bool {
        return status == .error
    }
}

/// Additional protocol for tools that support advanced features
protocol AdvancedAgentProtocol: AgentProtocol {
    /// Execute a command with specific parameters
    func executeCommand(command: String, parameters: [String: Any]) async throws -> String

    /// Get current tool configuration
    func getConfiguration() -> [String: Any]

    /// Update tool configuration
    func updateConfiguration(_ config: [String: Any]) async throws
}

/// Default implementation for optional advanced features
extension AdvancedAgentProtocol {
    func executeCommand(command: String, parameters: [String: Any]) async throws -> String {
        // Default implementation simply calls process
        return try await process(input: command)
    }

    func getConfiguration() -> [String: Any] {
        return [:]
    }

    func updateConfiguration(_ config: [String: Any]) async throws {
        // Default implementation does nothing
    }
}
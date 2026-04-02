import Foundation
import Combine

/// Base implementation of AgentProtocol to facilitate integration of AI tools
final class AIBaseAgent: AgentProtocol, ObservableObject {
    // MARK: - AgentProtocol Properties
    let id: UUID
    let name: String
    let type: AITool.ToolType

    @Published private(set) var status: AITool.ToolStatus = .idle
    @Published private(set) var isActive: Bool = false
    @Published private(set) var lastActivity: Date? = nil

    var statusPublisher: AnyPublisher<AITool.ToolStatus, Never> {
        $status.eraseToAnyPublisher()
    }

    var activityPublisher: AnyPublisher<Bool, Never> {
        $isActive.eraseToAnyPublisher()
    }

    // Private publishers for internal use
    private let statusSubject = PassthroughSubject<AITool.ToolStatus, Never>()
    private let activitySubject = PassthroughSubject<Bool, Never>()

    // MARK: - Initialization
    init(id: UUID = UUID(), name: String, type: AITool.ToolType) {
        self.id = id
        self.name = name
        self.type = type
    }

    // MARK: - AgentProtocol Methods
    func initialize() {
        // Basic initialization - subclasses can override
        updateStatus(.idle)
    }

    func start() async throws {
        // Default implementation - should be overridden by subclasses
        updateStatus(.running)
        updateActivity(true)
        lastActivity = Date()
    }

    func stop() async throws {
        // Default implementation - should be overridden by subclasses
        updateStatus(.idle)
        updateActivity(false)
    }

    func isRunning() -> Bool {
        return isActive && status == .running
    }

    func process(input: String) async throws -> String {
        // Default implementation - should be overridden by subclasses
        throw NotImplementedError("process(input:) not implemented for \(name)")
    }

    // MARK: - Internal Methods for Subclasses
    func updateStatus(_ newStatus: AITool.ToolStatus) {
        DispatchQueue.main.async {
            self.status = newStatus
        }
    }

    func updateActivity(_ active: Bool) {
        DispatchQueue.main.async {
            self.isActive = active
            self.lastActivity = active ? Date() : self.lastActivity
        }
    }

    func updateLastActivity() {
        DispatchQueue.main.async {
            self.lastActivity = Date()
        }
    }
}

// MARK: - Custom Error
struct NotImplementedError: Error, LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        return message
    }
}
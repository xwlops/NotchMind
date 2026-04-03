import Foundation
import Combine

// MARK: - AI Tool Protocol
protocol AIToolProtocol: AnyObject {
    var id: UUID { get }
    var name: String { get }
    var version: String { get }
    var isActive: Bool { get }
    var status: AITool.ToolStatus { get }

    // Lifecycle methods
    func connect() async throws
    func disconnect() async throws

    // Core functionality
    func executeCommand(_ command: String) async throws -> String
    func executeScript(_ script: String) async throws -> String

    // Event handling
    var onStatusChange: ((AITool.ToolStatus) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
}

// MARK: - AI Tool Manager
final class AIToolManager: ObservableObject {
    static let shared = AIToolManager()

    @Published var connectedTools: [UUID: AIToolProtocol] = [:]
    @Published var availableTools: [AIToolDescriptor] = []

    private var isInitialized = false

    private init() {
        // Defer initialization to reduce startup memory
    }

    // Lazy initialization
    private func ensureInitialized() {
        guard !isInitialized else { return }
        isInitialized = true
        discoverAvailableTools()
    }

    // Discover available AI tools (called lazily)
    private func discoverAvailableTools() {
        // Simulate discovering available tools
        availableTools = [
            AIToolDescriptor(id: UUID(), name: "Claude Code", type: .claudeCode, executable: "claude", supportedFeatures: [.commandExecution, .scriptExecution]),
            AIToolDescriptor(id: UUID(), name: "GitHub Copilot", type: .codex, executable: "copilot", supportedFeatures: [.commandExecution]),
            AIToolDescriptor(id: UUID(), name: "Google Gemini", type: .geminiCLI, executable: "gemini", supportedFeatures: [.commandExecution, .scriptExecution]),
            AIToolDescriptor(id: UUID(), name: "Cursor", type: .cursor, executable: "cursor", supportedFeatures: [.commandExecution]),
            AIToolDescriptor(id: UUID(), name: "OpenCode", type: .openCode, executable: "opencode", supportedFeatures: [.commandExecution, .scriptExecution]),
            AIToolDescriptor(id: UUID(), name: "Droid", type: .droid, executable: "droid", supportedFeatures: [.commandExecution])
        ]
    }

    // Lazy getter for available tools
    func getAvailableTools() -> [AIToolDescriptor] {
        ensureInitialized()
        return availableTools
    }

    // Connect to an AI tool
    func connect(to descriptor: AIToolDescriptor) async throws -> AIToolProtocol {
        ensureInitialized()
        let tool: AIToolProtocol

        switch descriptor.type {
        case .claudeCode:
            tool = ClaudeCodeAdapter(descriptor: descriptor)
        case .codex:
            tool = GitHubCopilotAdapter(descriptor: descriptor)
        case .geminiCLI:
            tool = GeminiAdapter(descriptor: descriptor)
        case .cursor:
            tool = CursorAdapter(descriptor: descriptor)
        case .openCode:
            tool = OpenCodeAdapter(descriptor: descriptor)
        case .droid:
            tool = DroidAdapter(descriptor: descriptor)
        }

        try await tool.connect()
        connectedTools[tool.id] = tool

        // Set up event handlers
        tool.onStatusChange = { status in
            DispatchQueue.main.async {
                // Update the tool in the main app state
                // This would trigger UI updates
            }
        }

        tool.onError = { error in
            DispatchQueue.main.async {
                // Handle error, perhaps log or show to user
                print("AI Tool Error: \(error)")
            }
        }

        return tool
    }

    // Disconnect from an AI tool
    func disconnect(_ toolId: UUID) async throws {
        guard let tool = connectedTools[toolId] else {
            throw AIToolError.toolNotFound
        }

        try await tool.disconnect()
        connectedTools.removeValue(forKey: toolId)
    }

    // Execute a command on a connected tool
    func executeCommand(_ command: String, on toolId: UUID) async throws -> String {
        guard let tool = connectedTools[toolId] else {
            throw AIToolError.toolNotConnected
        }

        return try await tool.executeCommand(command)
    }

    // Execute a script on a connected tool
    func executeScript(_ script: String, on toolId: UUID) async throws -> String {
        guard let tool = connectedTools[toolId] else {
            throw AIToolError.toolNotConnected
        }

        return try await tool.executeScript(script)
    }

    // Get tool by ID
    func getTool(withId id: UUID) -> AIToolProtocol? {
        return connectedTools[id]
    }

    // Check if a tool is connected
    func isConnected(_ toolId: UUID) -> Bool {
        return connectedTools.keys.contains(toolId)
    }
}

// MARK: - Tool Descriptor
struct AIToolDescriptor {
    let id: UUID
    let name: String
    let type: AITool.ToolType
    let executable: String
    let supportedFeatures: [AIToolFeature]
}

enum AIToolFeature {
    case commandExecution
    case scriptExecution
    case fileAccess
    case terminalIntegration
}

// MARK: - AI Tool Errors
enum AIToolError: LocalizedError {
    case toolNotFound
    case toolNotConnected
    case connectionFailed(String)
    case executionFailed(String)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .toolNotFound:
            return "AI tool not found"
        case .toolNotConnected:
            return "AI tool not connected"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .executionFailed(let reason):
            return "Execution failed: \(reason)"
        case .notImplemented:
            return "Feature not implemented"
        }
    }
}

// MARK: - Base Adapter Class
class BaseAIToolAdapter: AIToolProtocol {
    let id: UUID
    let name: String
    let version: String
    var isActive: Bool = false
    var status: AITool.ToolStatus = .idle

    var onStatusChange: ((AITool.ToolStatus) -> Void)?
    var onError: ((Error) -> Void)?

    private let descriptor: AIToolDescriptor

    init(descriptor: AIToolDescriptor) {
        self.descriptor = descriptor
        self.id = descriptor.id
        self.name = descriptor.name
        self.version = "1.0.0" // Default version
    }

    func connect() async throws {
        isActive = true
        status = .running
        onStatusChange?(status)
    }

    func disconnect() async throws {
        isActive = false
        status = .idle
        onStatusChange?(status)
    }

    func executeCommand(_ command: String) async throws -> String {
        throw AIToolError.notImplemented
    }

    func executeScript(_ script: String) async throws -> String {
        throw AIToolError.notImplemented
    }
}

// MARK: - Concrete Adapters
class ClaudeCodeAdapter: BaseAIToolAdapter {
    override func executeCommand(_ command: String) async throws -> String {
        // Simulate Claude Code command execution
        return "Claude Code response to: \(command)"
    }

    override func executeScript(_ script: String) async throws -> String {
        // Simulate Claude Code script execution
        return "Claude Code executed script with result"
    }
}

class GitHubCopilotAdapter: BaseAIToolAdapter {
    override func executeCommand(_ command: String) async throws -> String {
        // Simulate GitHub Copilot command execution
        return "GitHub Copilot response to: \(command)"
    }
}

class GeminiAdapter: BaseAIToolAdapter {
    override func executeCommand(_ command: String) async throws -> String {
        // Simulate Gemini command execution
        return "Gemini response to: \(command)"
    }

    override func executeScript(_ script: String) async throws -> String {
        // Simulate Gemini script execution
        return "Gemini executed script with result"
    }
}

class CursorAdapter: BaseAIToolAdapter {
    override func executeCommand(_ command: String) async throws -> String {
        // Simulate Cursor command execution
        return "Cursor response to: \(command)"
    }
}

class OpenCodeAdapter: BaseAIToolAdapter {
    override func executeCommand(_ command: String) async throws -> String {
        // Simulate OpenCode command execution
        return "OpenCode response to: \(command)"
    }

    override func executeScript(_ script: String) async throws -> String {
        // Simulate OpenCode script execution
        return "OpenCode executed script with result"
    }
}

class DroidAdapter: BaseAIToolAdapter {
    override func executeCommand(_ command: String) async throws -> String {
        // Simulate Droid command execution
        return "Droid response to: \(command)"
    }
}

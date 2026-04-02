import Foundation

/// Represents an AI coding tool that NotchMind monitors
struct AITool: Identifiable, Hashable {
    let id: UUID
    let name: String
    let type: ToolType
    var status: ToolStatus
    var isActive: Bool
    var lastActivity: Date?
    var permissionRequests: Int

    enum ToolType: String, CaseIterable {
        case claudeCode = "Claude Code"
        case codex = "Codex"
        case geminiCLI = "Gemini CLI"
        case cursor = "Cursor"
        case openCode = "OpenCode"
        case droid = "Droid"

        var iconName: String {
            switch self {
            case .claudeCode: return "brain"
            case .codex: return "terminal"
            case .geminiCLI: return "sparkles"
            case .cursor: return "cursorarrow"
            case .openCode: return "chevron.left.forwardslash.chevron.right"
            case .droid: return "ant"
            }
        }
    }

    enum ToolStatus: String {
        case idle
        case running
        case waiting
        case error
        case disabled
    }

    init(id: UUID = UUID(), name: String, type: ToolType, status: ToolStatus = .idle, isActive: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.isActive = isActive
        self.lastActivity = nil
        self.permissionRequests = 0
    }
}
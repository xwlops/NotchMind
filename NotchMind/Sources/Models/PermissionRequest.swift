import Foundation

/// Represents a permission request from an AI tool
struct PermissionRequest: Identifiable, Hashable {
    let id: UUID
    let toolId: UUID
    let toolName: String
    let permissionType: PermissionType
    let description: String
    let timestamp: Date
    var status: PermissionStatus

    enum PermissionType: String, CaseIterable {
        case fileAccess = "File Access"
        case shellCommand = "Shell Command"
        case networkAccess = "Network Access"
        case clipboard = "Clipboard"
        case keyboard = "Keyboard Control"
        case processControl = "Process Control"

        var iconName: String {
            switch self {
            case .fileAccess: return "folder"
            case .shellCommand: return "terminal"
            case .networkAccess: return "network"
            case .clipboard: return "doc.on.clipboard"
            case .keyboard: return "keyboard"
            case .processControl: return "gearshape.2"
            }
        }

        var riskLevel: RiskLevel {
            switch self {
            case .fileAccess: return .medium
            case .shellCommand: return .high
            case .networkAccess: return .low
            case .clipboard: return .low
            case .keyboard: return .high
            case .processControl: return .high
            }
        }
    }

    enum RiskLevel: String {
        case low
        case medium
        case high

        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "red"
            }
        }
    }

    enum PermissionStatus: String {
        case pending
        case approved
        case denied
        case expired
    }

    init(id: UUID = UUID(), toolId: UUID, toolName: String, permissionType: PermissionType, description: String) {
        self.id = id
        self.toolId = toolId
        self.toolName = toolName
        self.permissionType = permissionType
        self.description = description
        self.timestamp = Date()
        self.status = .pending
    }
}
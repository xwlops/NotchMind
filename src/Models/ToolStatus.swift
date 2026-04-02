//
//  NotchMind - Tool Status Models
//  ToolStatus.swift
//

import Foundation

/// Status of an AI tool
enum ToolStatus: String, Codable {
    case online
    case busy
    case offline
    case requestingPermission

    var displayColor: String {
        switch self {
        case .online: return "#50fa7b"     // Green
        case .busy: return "#f1fa8c"       // Yellow
        case .offline: return "#ff5555"   // Red
        case .requestingPermission: return "#bd93f9"  // Blue/Purple
        }
    }

    var description: String {
        switch self {
        case .online: return "Online"
        case .busy: return "Busy"
        case .offline: return "Offline"
        case .requestingPermission: return "Permission Request"
        }
    }
}

/// Represents a single AI tool's current state
struct AIToolState: Identifiable, Codable {
    let id: UUID
    let toolType: AIToolType
    var status: ToolStatus
    var lastUpdated: Date
    var details: String?

    init(toolType: AIToolType, status: ToolStatus = .offline, details: String? = nil) {
        self.id = UUID()
        self.toolType = toolType
        self.status = status
        self.lastUpdated = Date()
        self.details = details
    }
}

/// Permission request from an AI tool
struct PermissionRequest: Identifiable, Codable {
    let id: UUID
    let sourceTool: AIToolType
    let permissionType: PermissionType
    let details: String
    let timestamp: Date

    init(sourceTool: AIToolType, permissionType: PermissionType, details: String) {
        self.id = UUID()
        self.sourceTool = sourceTool
        self.permissionType = permissionType
        self.details = details
        self.timestamp = Date()
    }
}

/// Types of permissions that can be requested
enum PermissionType: String, Codable, CaseIterable {
    case fileRead
    case fileWrite
    case networkAccess
    case shellExecution
    case systemPermission
    case apiCall

    var displayName: String {
        switch self {
        case .fileRead: return "File Read Access"
        case .fileWrite: return "File Write Access"
        case .networkAccess: return "Network Access"
        case .shellExecution: return "Shell Execution"
        case .systemPermission: return "System Permission"
        case .apiCall: return "API Call"
        }
    }

    var icon: String {
        switch self {
        case .fileRead: return "doc.text"
        case .fileWrite: return "doc.badge.plus"
        case .networkAccess: return "network"
        case .shellExecution: return "terminal"
        case .systemPermission: return "gearshape"
        case .apiCall: return "arrow.triangle.branch"
        }
    }
}

/// Response to a permission request
struct PermissionResponse: Codable {
    let requestId: UUID
    let decision: PermissionDecision
    let expiresAt: Date?
    let timestamp: Date

    init(requestId: UUID, decision: PermissionDecision, expiresAt: Date? = nil) {
        self.requestId = requestId
        self.decision = decision
        self.expiresAt = expiresAt
        self.timestamp = Date()
    }
}

/// Permission decision types
enum PermissionDecision: String, Codable {
    case approved
    case denied
    case temporary
    case pending
}
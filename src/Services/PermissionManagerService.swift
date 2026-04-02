//
//  NotchMind - Permission Manager Service
//  PermissionManagerService.swift
//

import Foundation
import Combine

/// Service responsible for managing AI tool permission requests
final class PermissionManagerService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var permissionRequests: [PermissionRequest] = []
    @Published private(set) var permissionHistory: [PermissionResponse] = []

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // Limits to prevent memory growth
    private let maxHistoryCount = 1000

    // MARK: - Initialization

    init() {
        loadPermissionHistory()
    }

    // MARK: - Public Methods

    /// Submit a new permission request
    func submitRequest(_ request: PermissionRequest) {
        permissionRequests.append(request)
    }

    /// Approve a permission request
    func approveRequest(_ requestId: UUID, temporary: Bool = false) -> Bool {
        guard let index = permissionRequests.firstIndex(where: { $0.id == requestId }) else {
            return false
        }

        let expiresAt: Date? = temporary ? Date().addingTimeInterval(3600) : nil
        let decision: PermissionDecision = temporary ? .temporary : .approved

        let response = PermissionResponse(
            requestId: requestId,
            decision: decision,
            expiresAt: expiresAt
        )

        permissionHistory.append(response)
        permissionRequests.remove(at: index)

        // Cleanup old history records
        cleanupHistory()

        return true
    }

    /// Deny a permission request
    func denyRequest(_ requestId: UUID) -> Bool {
        guard let index = permissionRequests.firstIndex(where: { $0.id == requestId }) else {
            return false
        }

        let response = PermissionResponse(
            requestId: requestId,
            decision: .denied
        )

        permissionHistory.append(response)
        permissionRequests.remove(at: index)

        // Cleanup old history records
        cleanupHistory()

        return true
    }

    /// Get pending requests for a specific tool
    func pendingRequests(for tool: AIToolType) -> [PermissionRequest] {
        return permissionRequests.filter { $0.sourceTool == tool }
    }

    /// Check if a tool has permission for a specific action
    func hasPermission(_ tool: AIToolType, for permissionType: PermissionType) -> Bool {
        // Check recent history for permanent approvals
        let relevantHistory = permissionHistory.filter { response in
            guard let request = permissionRequests.first(where: { $0.id == response.requestId }),
                  request.sourceTool == tool,
                  request.permissionType == permissionType else {
                return false
            }
            return true
        }

        // Check if there's a non-expired temporary or permanent approval
        return relevantHistory.contains { response in
            switch response.decision {
            case .approved:
                return true
            case .temporary:
                if let expiresAt = response.expiresAt {
                    return expiresAt > Date()
                }
                return false
            default:
                return false
            }
        }
    }

    /// Clear all pending requests
    func clearPendingRequests() {
        permissionRequests.removeAll()
    }

    /// Get permission statistics
    func getStatistics() -> (total: Int, approved: Int, denied: Int, pending: Int) {
        let approved = permissionHistory.filter { $0.decision == .approved || $0.decision == .temporary }.count
        let denied = permissionHistory.filter { $0.decision == .denied }.count

        return (
            total: permissionHistory.count + permissionRequests.count,
            approved: approved,
            denied: denied,
            pending: permissionRequests.count
        )
    }

    /// Cleanup old history records to prevent memory growth
    private func cleanupHistory() {
        if permissionHistory.count > maxHistoryCount {
            let excessCount = permissionHistory.count - maxHistoryCount
            permissionHistory.removeFirst(excessCount)
        }
    }

    // MARK: - Private Methods

    private func loadPermissionHistory() {
        // Load from UserDefaults in production
        // For now, start with empty history
    }

    private func savePermissionHistory() {
        // Save to UserDefaults in production
    }

    deinit {
        savePermissionHistory()
    }
}
import Foundation
import Combine

/// Manages permission requests from AI tools
final class PermissionManager: ObservableObject {
    @Published var pendingRequests: [PermissionRequest] = []
    @Published var approvedHistory: [PermissionRequest] = []
    @Published var deniedHistory: [PermissionRequest] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        loadHistory()
    }

    func approve(_ request: PermissionRequest) {
        var updatedRequest = request
        updatedRequest.status = .approved

        pendingRequests.removeAll { $0.id == request.id }
        approvedHistory.insert(updatedRequest, at: 0)
        saveHistory()
        sendResponse(to: request, approved: true)
    }

    func deny(_ request: PermissionRequest) {
        var updatedRequest = request
        updatedRequest.status = .denied

        pendingRequests.removeAll { $0.id == request.id }
        deniedHistory.insert(updatedRequest, at: 0)
        saveHistory()
        sendResponse(to: request, approved: false)
    }

    func addRequest(_ request: PermissionRequest) {
        pendingRequests.append(request)
    }

    func clearExpired() {
        let expirationTime: TimeInterval = 5 * 60 // 5 minutes
        let now = Date()

        pendingRequests.removeAll { request in
            now.timeIntervalSince(request.timestamp) > expirationTime
        }
    }

    private func sendResponse(to request: PermissionRequest, approved: Bool) {
        // In a real implementation, this would communicate back to the AI tool
        // For now, this is a placeholder for the integration
        print("Permission \(approved ? "approved" : "denied") for \(request.toolName): \(request.permissionType.rawValue)")
    }

    private func loadHistory() {
        // Load from UserDefaults in a full implementation
    }

    private func saveHistory() {
        // Save to UserDefaults in a full implementation
    }
}
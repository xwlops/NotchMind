//
//  NotchMind - Notch Panel ViewModel
//  NotchPanelViewModel.swift
//

import Foundation
import Combine

/// ViewModel for the Notch Panel
@MainActor
final class NotchPanelViewModel: BaseViewModel {

    // MARK: - Published Properties

    @Published var toolStates: [AIToolType: AIToolState] = [:]
    @Published var pendingRequests: [PermissionRequest] = []
    @Published var isPanelVisible: Bool = false

    // MARK: - Private Properties

    private let monitorService: AIToolMonitorService
    private let permissionManager: PermissionManagerService
    private let panelController: NotchPanelController

    // MARK: - Initialization

    init(monitorService: AIToolMonitorService, permissionManager: PermissionManagerService, panelController: NotchPanelController) {
        self.monitorService = monitorService
        self.permissionManager = permissionManager
        self.panelController = panelController
        super.init()

        setupBindings()
    }

    // MARK: - Private Methods

    private func setupBindings() {
        // Bind tool states
        monitorService.$toolStates
            .receive(on: DispatchQueue.main)
            .assign(to: &$toolStates)

        // Bind permission requests
        monitorService.$activePermissionRequests
            .receive(on: DispatchQueue.main)
            .assign(to: &$pendingRequests)
    }

    // MARK: - Public Methods

    func togglePanel() {
        isPanelVisible.toggle()
        if isPanelVisible {
            panelController.showPanel()
        } else {
            panelController.hidePanel()
        }
    }

    func approveRequest(_ requestId: UUID) {
        _ = permissionManager.approveRequest(requestId)
    }

    func denyRequest(_ requestId: UUID) {
        _ = permissionManager.denyRequest(requestId)
    }

    func refreshToolStatus() {
        monitorService.checkAllToolsStatus()
    }
}
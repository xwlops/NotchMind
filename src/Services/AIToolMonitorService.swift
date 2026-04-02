//
//  NotchMind - AI Tool Monitor Service
//  AIToolMonitorService.swift
//

import Foundation
import Combine
import AppKit

/// Service responsible for monitoring AI tool processes and status
final class AIToolMonitorService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var toolStates: [AIToolType: AIToolState] = [:]
    @Published private(set) var activePermissionRequests: [PermissionRequest] = []

    // MARK: - Private Properties

    private let permissionManager: PermissionManagerService
    private var monitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Reduce default monitor interval to minimize resource usage
    private let monitorInterval: TimeInterval = 10.0

    // Track ongoing tasks to prevent duplicate work
    private var activeTasks = Set<Task<Void, Error>>()

    // Cache for process information to reduce repeated system calls
    private var processCache: [String: Bool] = [:]
    private let cacheQueue = DispatchQueue(label: "com.notchmind.cache", attributes: .concurrent)

    // Limit the size of the cache
    private let maxCacheSize = 50

    // MARK: - Initialization

    init(permissionManager: PermissionManagerService) {
        self.permissionManager = permissionManager
        initializeToolStates()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        guard monitoringTimer == nil else { return }

        // Initial check
        checkAllToolsStatus()

        // Schedule periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitorInterval, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            Task { @MainActor in
                // Prevent concurrent monitoring tasks
                if !self.activeTasks.isEmpty {
                    return
                }

                self.checkAllToolsStatus()
            }
        }

        // Listen for permission requests
        setupPermissionRequestSubscription()
    }

    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil

        // Cancel all active tasks
        for task in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
    }

    func checkToolStatus(_ tool: AIToolType) {
        Task { @MainActor in
            let status = await detectToolStatus(tool)
            updateToolState(tool, status: status)
        }
    }

    func handlePermissionRequest(_ request: PermissionRequest) {
        activePermissionRequests.append(request)
        updateToolState(request.sourceTool, status: .requestingPermission)
    }

    // MARK: - Private Methods

    private func initializeToolStates() {
        for tool in AIToolType.allCases {
            toolStates[tool] = AIToolState(toolType: tool, status: .offline)
        }
    }

    private func setupPermissionRequestSubscription() {
        permissionManager.$permissionRequests
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requests in
                self?.activePermissionRequests = requests
            }
            .store(in: &cancellables)
    }

    private func checkAllToolsStatus() {
        // Create a new task and track it
        let task = Task {
            for tool in AIToolType.allCases {
                // Check for cancellation
                try Task.checkCancellation()

                let status = await detectToolStatus(tool)
                await MainActor.run {
                    updateToolState(tool, status: status)
                }
            }
        }

        activeTasks.insert(task)

        // Remove the task when it completes
        Task {
            await task.value
            await MainActor.run {
                activeTasks.remove(task)
            }
        }
    }

    private func detectToolStatus(_ tool: AIToolType) async -> ToolStatus {
        // Check if process is running
        let running = isProcessRunning(tool)

        if !running {
            return .offline
        }

        // Check for active permission requests
        if activePermissionRequests.contains(where: { $0.sourceTool == tool }) {
            return .requestingPermission
        }

        // Tool is running
        return .online
    }

    private func isProcessRunning(_ tool: AIToolType) -> Bool {
        // Check cache first
        let processName = tool.processName
        if let cachedResult = cacheQueue.sync(execute: { processCache[processName] }) {
            return cachedResult
        }

        let runningApps = NSWorkspace.shared.runningApplications

        // Check for app bundle identifier
        if let bundleId = tool.bundleIdentifier {
            if runningApps.contains(where: { $0.bundleIdentifier == bundleId }) {
                // Update cache
                cacheQueue.async(flags: .barrier) {
                    if processCache.count >= maxCacheSize {
                        processCache.removeAll()
                    }
                    processCache[processName] = true
                }
                return true
            }
        }

        // Check process list for CLI tools
        let task = Process()
        task.launchPath = "/bin/ps"
        task.arguments = ["-a", "-c", "-o", "comm"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let result = output.contains(processName)

                // Update cache
                cacheQueue.async(flags: .barrier) {
                    if processCache.count >= maxCacheSize {
                        processCache.removeAll()
                    }
                    processCache[processName] = result
                }

                return result
            }
        } catch {
            // Fallback: check running apps
            let result = runningApps.contains { app in
                app.localizedName?.lowercased().contains(processName.lowercased()) ?? false
            }

            // Update cache
            cacheQueue.async(flags: .barrier) {
                if processCache.count >= maxCacheSize {
                    processCache.removeAll()
                }
                processCache[processName] = result
            }

            return result
        }

        // Return false if we couldn't determine
        cacheQueue.async(flags: .barrier) {
            if processCache.count >= maxCacheSize {
                processCache.removeAll()
            }
            processCache[processName] = false
        }

        return false
    }

    private func updateToolState(_ tool: AIToolType, status: ToolStatus) {
        toolStates[tool] = AIToolState(toolType: tool, status: status, details: nil)
    }

    /// Clear the process cache to free memory
    func clearCache() {
        cacheQueue.async(flags: .barrier) {
            processCache.removeAll()
        }
    }

    deinit {
        stopMonitoring()
        clearCache()
    }
}
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status
            HStack {
                Image(systemName: appState.isMonitoring ? "eye.fill" : "eye.slash")
                    .foregroundColor(stateColor)

                Text(appState.isMonitoring ? "Monitoring" : "Paused")

                Spacer()

                // Enhanced status indicator
                Circle()
                    .fill(stateColor)
                    .frame(width: 10, height: 10)
                    .pulseEffect(isActive: appState.currentNotchState == .running)
                    .shakeEffect(shouldShake: appState.currentNotchState == .error)
            }

            Divider()

            // Active Tools
            if !appState.monitoredTools.filter({ $0.isActive }).isEmpty {
                Text("Active Tools")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(appState.monitoredTools.filter { $0.isActive }) { tool in
                    HStack {
                        Circle()
                            .fill(toolStatusColor(tool.status))
                            .frame(width: 6, height: 6)
                            .pulseEffect(isActive: tool.status == .running)
                            .shakeEffect(shouldShake: tool.status == .error)

                        Text(tool.type.rawValue)
                    }
                }

                Divider()
            }

            // Pending Permissions
            if !appState.pendingPermissions.isEmpty {
                Text("Pending Permissions (\(appState.pendingPermissions.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(appState.pendingPermissions.prefix(3)) { request in
                    HStack {
                        Image(systemName: request.permissionType.iconName)
                            .foregroundColor(.orange)
                            .shakeEffect(shouldShake: true) // Highlight permission requests

                        Text(request.permissionType.rawValue)
                        Spacer()
                        Button("Approve") {
                            appState.approvePermission(request)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                Divider()
            }

            // Actions
            Button("Open Terminal") {
                appState.openTerminal()
            }

            Button("Refresh") {
                appState.aiMonitorService.forceRefresh()
            }

            Divider()

            // Performance
            HStack {
                Text("Memory:")
                Text(String(format: "%.1f MB", appState.memoryUsage))
                    .foregroundColor(.secondary)
            }
            .font(.caption)

            Divider()

            Button("Quit NotchMind") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(8)
    }

    private var stateColor: Color {
        return appState.currentNotchState.color
    }

    private func toolStatusColor(_ status: AITool.ToolStatus) -> Color {
        switch status {
        case .idle:
            return AgentColors.waiting
        case .running:
            return AgentColors.running
        case .waiting:
            return AgentColors.waiting
        case .error:
            return AgentColors.error
        case .disabled:
            return AgentColors.permissionRequest
        }
    }
}
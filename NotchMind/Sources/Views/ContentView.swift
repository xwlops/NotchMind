import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(appState: appState)

            Divider()

            // Main Content
            if appState.pendingPermissions.isEmpty {
                ToolListView(appState: appState)
            } else {
                PermissionListView(appState: appState)
            }

            Divider()

            // Status Bar
            StatusBarView(appState: appState)
        }
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct HeaderView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack {
            Image(systemName: "cpu")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("NotchMind")
                .font(.headline)

            Spacer()

            Button(action: {
                appState.aiMonitorService.forceRefresh()
            }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh")

            Toggle("Monitor", isOn: $appState.isMonitoring)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding()
    }
}

struct ToolListView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(appState.monitoredTools) { tool in
                    ToolRowView(tool: tool, appState: appState)
                }
            }
            .padding()
        }
    }
}

struct ToolRowView: View {
    let tool: AITool
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator with animations
            Circle()
                .fill(tool.isActive ? AgentColors.running : AgentColors.waiting)
                .frame(width: 8, height: 8)
                .pulseEffect(isActive: tool.status == .running)
                .shakeEffect(shouldShake: tool.status == .error)

            // Tool icon
            Image(systemName: tool.type.iconName)
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(width: 30)

            // Tool info
            VStack(alignment: .leading, spacing: 2) {
                Text(tool.type.rawValue)
                    .font(.headline)
                Text(tool.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Action buttons
            if tool.isActive {
                Button(action: {
                    appState.openTerminalWithContext(for: tool)
                }) {
                    Image(systemName: "terminal")
                }
                .buttonStyle(.borderless)
                .help("Open Terminal")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct PermissionListView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(appState.pendingPermissions) { request in
                    PermissionRowView(request: request, appState: appState)
                }
            }
            .padding()
        }
    }
}

struct PermissionRowView: View {
    let request: PermissionRequest
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: request.permissionType.iconName)
                    .foregroundColor(.orange)
                    .shakeEffect(shouldShake: true) // Highlight permission requests

                Text(request.permissionType.rawValue)
                    .font(.headline)

                Spacer()

                Text(request.toolName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(request.description)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Button("Deny") {
                    appState.denyPermission(request)
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Approve") {
                    appState.approvePermission(request)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct StatusBarView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 16) {
            // Memory usage
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                Text(String(format: "%.1f MB", appState.memoryUsage))
            }
            .font(.caption)

            // CPU usage
            HStack(spacing: 4) {
                Image(systemName: "cpu")
                Text(String(format: "%.1f%%", appState.cpuUsage))
            }
            .font(.caption)

            Spacer()

            // Active tools count
            Text("\(appState.monitoredTools.filter { $0.isActive }.count) active")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
    }
}
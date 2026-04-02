import SwiftUI

struct MultiToolSwitcherView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTool: AITool?
    @State private var isSwitcherExpanded = false

    var body: some View {
        VStack(spacing: 12) {
            // Tool selector header
            HStack {
                Text("AI Tools")
                    .font(.headline)

                Spacer()

                // Expand/collapse button
                Button(action: toggleSwitcher) {
                    Image(systemName: isSwitcherExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)

            // Expanded tool list
            if isSwitcherExpanded {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(appState.monitoredTools) { tool in
                            ToolSelectionRow(
                                tool: tool,
                                isSelected: selectedTool?.id == tool.id,
                                onSelect: { selectTool(tool) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 200)
            }

            // Selected tool panel
            if let selectedTool = selectedTool {
                SelectedToolPanel(tool: selectedTool)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            } else if let activeTool = appState.monitoredTools.first(where: { $0.isActive }) {
                // Default to first active tool if none selected
                SelectedToolPanel(tool: activeTool)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .onAppear {
            // Initialize with first active tool
            if let activeTool = appState.monitoredTools.first(where: { $0.isActive }) {
                selectTool(activeTool)
            }
        }
    }

    private func toggleSwitcher() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isSwitcherExpanded.toggle()
        }
    }

    private func selectTool(_ tool: AITool) {
        selectedTool = tool
    }
}

struct ToolSelectionRow: View {
    let tool: AITool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack {
            // Tool icon and status
            HStack(spacing: 8) {
                Image(systemName: tool.type.iconName)
                    .foregroundColor(toolStatusColor)

                Circle()
                    .fill(toolStatusColor)
                    .frame(width: 8, height: 8)
                    .pulseEffect(isActive: tool.status == .running)
                    .shakeEffect(shouldShake: tool.status == .error)
            }

            // Tool name and status
            VStack(alignment: .leading) {
                Text(tool.name.capitalized)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)

                Text(tool.status.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Selection indicator
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .onTapGesture {
            onSelect()
        }
    }

    private var toolStatusColor: Color {
        switch tool.status {
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

struct SelectedToolPanel: View {
    let tool: AITool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tool header
            HStack {
                Image(systemName: tool.type.iconName)
                    .font(.title2)
                    .foregroundColor(toolStatusColor)

                VStack(alignment: .leading) {
                    Text(tool.name.capitalized)
                        .font(.headline)

                    Text(tool.status.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(toolStatusColor)
                        .frame(width: 6, height: 6)
                        .pulseEffect(isActive: tool.status == .running)
                        .shakeEffect(shouldShake: tool.status == .error)

                    Text(tool.status.rawValue.prefix(1))
                        .font(.caption)
                }
            }

            Divider()

            // Tool controls
            HStack {
                Button("Quick Action") {
                    // Implement quick action for the selected tool
                }
                .buttonStyle(.borderedProminent)

                Button("Settings") {
                    // Open tool-specific settings
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Terminate") {
                    // Terminate the tool
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            // Tool-specific information
            VStack(alignment: .leading, spacing: 8) {
                Text("Information")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Grid(horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Text("Last Activity:")
                        Text(tool.lastActivity?.formatted() ?? "Never")
                            .foregroundColor(.secondary)
                    }

                    GridRow {
                        Text("Type:")
                        Text(tool.type.rawValue)
                            .foregroundColor(.secondary)
                    }

                    if tool.isActive {
                        GridRow {
                            Text("Status:")
                            HStack {
                                Circle()
                                    .fill(toolStatusColor)
                                    .frame(width: 6, height: 6)
                                Text(tool.status.rawValue.capitalized)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }

    private var toolStatusColor: Color {
        switch tool.status {
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

// MARK: - Preview
struct MultiToolSwitcherView_Previews: PreviewProvider {
    static var previews: some View {
        MultiToolSwitcherView()
            .environmentObject(AppState())
    }
}
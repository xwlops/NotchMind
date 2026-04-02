import SwiftUI
import AppKit

struct NotchPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var showTooltip = false
    @State private var mouseExitTimer: Timer?

    var body: some View {
        ZStack {
            // 主面板容器
            if isExpanded {
                expandedPanel
            } else {
                collapsedNotch
            }
        }
        .onHover { hovering in
            if hovering {
                // 鼠标悬停，显示tooltip
                showTooltip = true

                // Clear any existing timer if we re-enter while timer is running
                mouseExitTimer?.invalidate()

                // 使用 CADisplayLink 驱动动画以获得更精确的帧率控制
                DispatchQueue.main.asyncAfter(deadline: .now() + NotchAnimations.hoverDelay) {
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.8)) {
                        isExpanded = true
                    }
                }
            } else {
                // 鼠标离开，启动计时器，1.5秒后收起
                mouseExitTimer?.invalidate() // Cancel any existing timer first
                mouseExitTimer = Timer.scheduledTimer(withTimeInterval: NotchAnimations.mouseExitTimeout, repeats: false) { _ in
                    withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.9, blendDuration: 0.7)) {
                        isExpanded = false
                    }
                    showTooltip = false
                }
            }
        }
        .overlay {
            if showTooltip && !isExpanded {
                tooltipView
                    .offset(y: -30)
            }
        }
    }

    // 塌陷状态（刘海形状）
    private var collapsedNotch: some View {
        VStack {
            Circle()
                .fill(currentStateColor)
                .frame(width: 12, height: 12)
                .pulseEffect(isActive: currentState == .running)
                .shakeEffect(shouldShake: currentState == .error)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.8)))
        .onTapGesture {
            withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.8)) {
                isExpanded = true
            }
        }
    }

    // 展开状态（功能面板）
    private var expandedPanel: some View {
        VStack(spacing: 12) {
            // 标题栏
            HStack {
                Text("NotchMind")
                    .font(.headline)

                Spacer()

                Button(action: {
                    withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.85, blendDuration: 0.7)) {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // 代理状态面板
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Agents")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if appState.detectedTools.isEmpty {
                    // 空数据状态处理
                    VStack(alignment: .center, spacing: 8) {
                        Image(systemName: "wave.3.left.and.line.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("No AI tools detected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Activate an AI agent to begin")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ForEach(appState.detectedTools) { tool in
                        HStack {
                            Circle()
                                .fill(agentStateToColor(tool.status))
                                .frame(width: 8, height: 8)

                            Text(tool.name.capitalized)
                                .font(.caption)

                            Spacer()

                            Text(tool.status.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .padding(.vertical, 4)

            // 快速操作按钮
            HStack(spacing: 8) {
                Button("Activate AI") {
                    // 激活AI代理的操作
                }
                .buttonStyle(.borderedProminent)

                Button("Settings") {
                    // 设置操作
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(width: 280, height: 200)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    // 工具提示视图
    private var tooltipView: some View {
        HStack {
            Text("Status: \(currentState.displayName)")
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.8)))
        .zIndex(999)
    }

    // 计算属性：当前整体状态
    private var currentState: AgentState {
        let activeTools = appState.detectedTools.filter { $0.isActive }

        if activeTools.contains(where: { $0.status == .error }) {
            return .error
        } else if activeTools.contains(where: { $0.status == .running }) {
            return .running
        } else if activeTools.contains(where: { $0.status == .waiting }) {
            return .waiting
        } else if activeTools.contains(where: { $0.status == .disabled }) {
            return .permissionRequest
        } else {
            return .waiting
        }
    }

    // 计算属性：当前状态颜色
    private var currentStateColor: Color {
        return currentState.color
    }

    // 将工具状态映射到颜色
    private func agentStateToColor(_ status: AITool.ToolStatus) -> Color {
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
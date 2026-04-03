import SwiftUI
import AppKit

struct NotchPanelView: View {
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var showTooltip = false
    @State private var mouseExitTimer: Timer?
    @State private var selectedMode: PanelMode = .monitor
    @State private var animateBackdrop = false
    @State private var animateCards = false

    var body: some View {
        ZStack(alignment: .top) {
            animatedBackdrop
                .opacity(isExpanded ? 1 : 0.15)
                .animation(.easeInOut(duration: 0.35), value: isExpanded)

            if isExpanded {
                expandedPanel
            } else {
                collapsedNotch
            }
        }
        .onHover { hovering in
            if hovering {
                showTooltip = true
                mouseExitTimer?.invalidate()

                DispatchQueue.main.asyncAfter(deadline: .now() + NotchAnimations.hoverDelay) {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                        isExpanded = true
                        animateCards = true
                    }
                }
            } else {
                mouseExitTimer?.invalidate()
                mouseExitTimer = Timer.scheduledTimer(withTimeInterval: NotchAnimations.mouseExitTimeout, repeats: false) { _ in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isExpanded = false
                        animateCards = false
                    }
                    showTooltip = false
                }
            }
        }
        .onAppear {
            animateBackdrop = true
        }
        .overlay {
            if showTooltip && !isExpanded {
                tooltipView
                    .offset(y: -30)
            }
        }
    }

    private var animatedBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x1D4ED8),
                    Color(hex: 0x2563EB),
                    Color(hex: 0x7C3AED),
                    Color(hex: 0xF59E0B)
                ],
                startPoint: animateBackdrop ? .topLeading : .bottomLeading,
                endPoint: animateBackdrop ? .bottomTrailing : .topTrailing
            )
            .blur(radius: 14)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    Color.black.opacity(0.15),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animateBackdrop)
    }

    private var collapsedNotch: some View {
        VStack {
            Circle()
                .fill(currentStateColor)
                .frame(width: 12, height: 12)
                .pulseEffect(isActive: currentState == .running)
                .shakeEffect(shouldShake: currentState == .error)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                isExpanded = true
                animateCards = true
            }
        }
    }

    private var expandedPanel: some View {
        VStack(spacing: 14) {
            topMonitorStrip
                .offset(y: animateCards ? 0 : -16)
                .opacity(animateCards ? 1 : 0)
                .animation(.spring(response: 0.42, dampingFraction: 0.84).delay(0.02), value: animateCards)

            mainTerminalCard
                .offset(y: animateCards ? 0 : 24)
                .opacity(animateCards ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.88).delay(0.06), value: animateCards)

            modeSwitcher
                .offset(y: animateCards ? 0 : 18)
                .opacity(animateCards ? 1 : 0)
                .animation(.spring(response: 0.44, dampingFraction: 0.9).delay(0.12), value: animateCards)
        }
        .frame(width: 980, height: 620)
        .padding(22)
    }

    private var topMonitorStrip: some View {
        HStack(spacing: 14) {
            statusRow(title: "fix auth bug", subtitle: "You: fix the auth bug in middleware", accent: AgentColors.running, tag1: "Claude", tag2: "iTerm")
            Spacer(minLength: 4)
            statusRow(title: "backend server", subtitle: "Watching routes and logs", accent: AgentColors.waiting, tag1: "Codex", tag2: "Terminal")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(glassBackground(cornerRadius: 18))
    }

    private var mainTerminalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                trafficLights
                Text("claude - \(selectedMode.rawValue)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isExpanded = false
                        animateCards = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                terminalLine("Let me look at the auth module.", color: AgentColors.running)
                terminalLine("Searching for 6 patterns...  (ctrl+o to expand)", color: .white.opacity(0.58))
                terminalLine("Read 2 files  (ctrl+o to expand)", color: .white.opacity(0.58))
                terminalLine("", color: .clear)
                terminalLine("Found the issue - token validation skips expiry check.", color: .white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
        .background(glassBackground(cornerRadius: 22))
    }

    private var modeSwitcher: some View {
        HStack(spacing: 10) {
            ForEach(PanelMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                        Text(mode.label)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.65))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMode == mode ? mode.color.opacity(0.3) : .white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedMode == mode ? mode.color.opacity(0.65) : .white.opacity(0.14), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(glassBackground(cornerRadius: 16))
    }

    private var trafficLights: some View {
        HStack(spacing: 8) {
            Circle().fill(Color(hex: 0xFF5F56)).frame(width: 10, height: 10)
            Circle().fill(Color(hex: 0xFFBD2E)).frame(width: 10, height: 10)
            Circle().fill(Color(hex: 0x27C93F)).frame(width: 10, height: 10)
        }
    }

    private func statusRow(
        title: String,
        subtitle: String,
        accent: Color,
        tag1: String,
        tag2: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Circle().fill(accent).frame(width: 8, height: 8)
                Text(title).font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundColor(.white)
                Spacer()
                tagView(tag1)
                tagView(tag2)
            }
            Text(subtitle)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.62))
        }
    }

    private func tagView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white.opacity(0.72))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.08))
            )
    }

    private func terminalLine(_ text: String, color: Color) -> some View {
        Text(text.isEmpty ? " " : "• \(text)")
            .font(.system(size: 28, weight: .regular, design: .monospaced))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func glassBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.black.opacity(0.46))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.44), radius: 26, x: 0, y: 12)
    }

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

    private var currentStateColor: Color {
        return currentState.color
    }

}

private enum PanelMode: String, CaseIterable {
    case monitor
    case approve
    case ask
    case jump

    var label: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .monitor: return "square.grid.2x2"
        case .approve: return "hexagon.fill"
        case .ask: return "bubble.left.and.bubble.right.fill"
        case .jump: return "arrowshape.turn.up.right"
        }
    }

    var color: Color {
        switch self {
        case .monitor: return Color(hex: 0x22C55E)
        case .approve: return Color(hex: 0xF97316)
        case .ask: return Color(hex: 0x06B6D4)
        case .jump: return Color(hex: 0x3B82F6)
        }
    }
}

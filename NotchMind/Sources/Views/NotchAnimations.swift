import SwiftUI
import AppKit

// MARK: - Animation Constants
struct NotchAnimations {
    // 展开动画参数
    static let expandDuration: TimeInterval = 0.35
    static let collapseDuration: TimeInterval = 0.25
    static let expandTimingCurve = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0)
    static let collapseTimingCurve = CAMediaTimingFunction(controlPoints: 0.34, 1.56, 0.64, 1.0)

    // 触发延迟参数
    static let hoverDelay: TimeInterval = 0.3
    static let mouseExitTimeout: TimeInterval = 1.5

    // 视觉反馈参数
    static let pulseAnimationKey = "pulse"
    static let pulseDuration: TimeInterval = 2.0
    static let shakeAnimationKey = "shake"
    static let shakeDuration: TimeInterval = 0.5
}

// MARK: - Agent State Colors
struct AgentColors {
    static let waiting = Color(hex: 0x6c7086) // 浅灰色
    static let running = Color(hex: 0x74c7ec) // 青蓝色
    static let completed = Color(hex: 0xa6e3a1) // 柔和绿色
    static let error = Color(hex: 0xf38ba8) // 珊瑚红色
    static let permissionRequest = Color(hex: 0xf5c2e7) // 淡粉色
}

// MARK: - Agent State Enum
enum AgentState: String, CaseIterable {
    case waiting = "waiting"
    case running = "running"
    case completed = "completed"
    case error = "error"
    case permissionRequest = "permissionRequest"

    var color: Color {
        switch self {
        case .waiting: return AgentColors.waiting
        case .running: return AgentColors.running
        case .completed: return AgentColors.completed
        case .error: return AgentColors.error
        case .permissionRequest: return AgentColors.permissionRequest
        }
    }

    var displayName: String {
        switch self {
        case .waiting: return "Waiting"
        case .running: return "Running"
        case .completed: return "Completed"
        case .error: return "Error"
        case .permissionRequest: return "Permission Request"
        }
    }
}

// MARK: - Custom Color Extension
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Animation View Modifiers
struct PulseEffect: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.05 : 1.0)
            .animation(.easeInOut(duration: NotchAnimations.pulseDuration).repeatForever(autoreverses: true), value: isActive)
    }
}

struct ShakeEffect: ViewModifier {
    let shouldShake: Bool

    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle(degrees: shouldShake ? 2 : 0))
            .animation(.easeInOut(duration: NotchAnimations.shakeDuration).repeatCount(3, autoreverses: true), value: shouldShake)
    }
}

extension View {
    func pulseEffect(isActive: Bool) -> some View {
        modifier(PulseEffect(isActive: isActive))
    }

    func shakeEffect(shouldShake: Bool) -> some View {
        modifier(ShakeEffect(shouldShake: shouldShake))
    }
}
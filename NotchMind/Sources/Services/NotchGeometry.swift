import Foundation
import AppKit

/**
 * NotchGeometry
 * 负责计算和管理 MacBook Pro 刘海区域的几何信息
 */
public class NotchGeometry {

    /**
     * 获取刘海区域的安全矩形
     * - Returns: 返回一个CGRect表示刘海区域下方的安全矩形区域
     */
    public static func getSafeAreaRect(for windowFrame: CGRect, screen: NSScreen) -> CGRect {
        let notchHeight = getNotchHeight()
        guard notchHeight > 0 else {
            // 如果没有刘海，则整个窗口都是安全区域
            return windowFrame
        }

        // 刘海区域通常位于屏幕顶部中央
        let notchWidth: CGFloat = 140  // 假设刘海宽度
        let screenFrame = screen.frame

        // 计算刘海在屏幕上的位置
        let notchRect = CGRect(
            x: screenFrame.midX - notchWidth / 2,
            y: screenFrame.maxY - notchHeight,
            width: notchWidth,
            height: notchHeight
        )

        // 计算窗口内的安全区域
        var safeArea = windowFrame

        // 如果窗口与刘海区域重叠，则调整安全区域
        if intersectsNotch(windowFrame, notchRect: notchRect, screen: screen) {
            // 将窗口的上边界下移，避开刘海
            safeArea.origin.y += notchHeight
            safeArea.size.height -= notchHeight
        }

        return safeArea
    }

    /**
     * 获取刘海高度
     * - Returns: 刘海的高度值，如果设备没有刘海则返回0
     */
    public static func getNotchHeight() -> CGFloat {
        // 检查是否为带刘海的Mac设备
        // 当前仅作为示例返回固定值，实际实现可能需要检测具体硬件型号
        return getSystemVersion() >= 12.0 ? 24 : 0  // macOS 12及以上版本可能支持刘海
    }

    /**
     * 获取系统版本
     * - Returns: 系统版本号
     */
    private static func getSystemVersion() -> Double {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return Double(version.majorVersion) + Double(version.minorVersion) / 10.0
    }

    /**
     * 判断窗口是否与刘海区域相交
     * - Parameters:
     *   - windowFrame: 窗口框架
     *   - notchRect: 刘海矩形区域（在屏幕坐标系中）
     *   - screen: 屏幕对象
     * - Returns: 如果相交返回true，否则返回false
     */
    private static func intersectsNotch(_ windowFrame: CGRect, notchRect: CGRect, screen: NSScreen) -> Bool {
        // Convert window frame to screen coordinates to match notchRect coordinate system
        let windowInScreenCoords = windowFrame

        // Check if the window intersects with the notch area in screen coordinates
        return windowInScreenCoords.intersects(notchRect)
    }

    /**
     * 获取刘海的矩形区域（相对于屏幕）
     * - Parameter screen: 屏幕对象
     * - Returns: 刘海矩形区域
     */
    public static func getNotchRect(for screen: NSScreen) -> CGRect {
        let notchHeight = getNotchHeight()
        guard notchHeight > 0 else {
            return CGRect.zero
        }

        let notchWidth: CGFloat = 140  // 假设刘海宽度
        let screenFrame = screen.frame

        // 刘海位于屏幕顶部中央
        return CGRect(
            x: screenFrame.midX - notchWidth / 2,
            y: screenFrame.maxY - notchHeight,
            width: notchWidth,
            height: notchHeight
        )
    }

    /**
     * 判断指定坐标点是否在刘海区域内
     * - Parameters:
     *   - point: 坐标点（相对于屏幕）
     *   - screen: 屏幕对象
     * - Returns: 如果在刘海内返回true，否则返回false
     */
    public static func isPointInNotch(_ point: CGPoint, screen: NSScreen) -> Bool {
        let notchRect = getNotchRect(for: screen)
        return notchRect.contains(point)
    }
}

// MARK: - Extension for easy access
extension NSScreen {
    /// 获取当前屏幕的刘海安全区域
    public var notchSafeArea: CGRect {
        let visibleFrame = self.visibleFrame
        return NotchGeometry.getSafeAreaRect(for: visibleFrame, screen: self)
    }

    /// 检查当前屏幕是否有刘海
    public var hasNotch: Bool {
        return NotchGeometry.getNotchHeight() > 0
    }
}

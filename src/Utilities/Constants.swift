//
//  NotchMind - Constants
//  Constants.swift
//

import Foundation

/// Application-wide constants
enum Constants {

    // MARK: - App Info

    enum App {
        static let name = "NotchMind"
        static let bundleIdentifier = "com.notchmind.app"
        static let version = "1.0.0"
        static let build = "1"
    }

    // MARK: - Performance

    enum Performance {
        static let maxMemoryMB = 50
        static let maxCPUIdlePercent = 2
        static let maxCPUWorkPercent = 15
        static let maxStartupSeconds = 2
        static let maxResponseMS = 100
    }

    // MARK: - UI

    enum UI {
        static let notchPanelWidth: CGFloat = 400
        static let notchPanelHeight: CGFloat = 200
        static let cornerRadius: CGFloat = 16
        static let animationDuration: TimeInterval = 0.3
    }

    // MARK: - Monitoring

    enum Monitoring {
        static let defaultIntervalSeconds: TimeInterval = 5.0
        static let quickCheckIntervalSeconds: TimeInterval = 1.0
    }

    // MARK: - Colors (Retro-Futuristic Palette)

    enum Colors {
        static let background = "#1e1e2e"
        static let accent = "#74c7ec"
        static let secondary = "#f5c2e7"
        static let text = "#cdd6f4"
        static let textSecondary = "#6c7086"
        static let statusOnline = "#50fa7b"
        static let statusBusy = "#f1fa8c"
        static let statusOffline = "#ff5555"
        static let statusPermission = "#bd93f9"
    }

    // MARK: - Storage Keys

    enum StorageKeys {
        static let permissionHistory = "notchmind_permission_history"
        static let toolConfigurations = "notchmind_tool_configs"
        static let userPreferences = "notchmind_preferences"
    }
}
//
//  NotchMind - AI Tool Types
//  AIToolType.swift
//

import Foundation

/// Represents the different AI coding tools that NotchMind can monitor
enum AIToolType: CaseIterable, Codable, Identifiable {
    case claudeCode
    case codex
    case geminiCLI
    case cursor
    case openCode
    case droid

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claudeCode: return "Claude Code"
        case .codex: return "Codex"
        case .geminiCLI: return "Gemini CLI"
        case .cursor: return "Cursor"
        case .openCode: return "OpenCode"
        case .droid: return "Droid"
        }
    }

    var processName: String {
        switch self {
        case .claudeCode: return "Claude"
        case .codex: return "node"
        case .geminiCLI: return "gemini"
        case .cursor: return "Cursor"
        case .openCode: return "OpenCode"
        case .droid: return "Droid"
        }
    }

    var bundleIdentifier: String? {
        switch self {
        case .claudeCode: return nil
        case .codex: return nil
        case .geminiCLI: return nil
        case .cursor: return "com.cursor.sh"
        case .openCode: return nil
        case .droid: return nil
        }
    }
}
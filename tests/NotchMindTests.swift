//
//  NotchMind - Basic Tests
//  NotchMindTests.swift
//

import XCTest
@testable import NotchMind

final class NotchMindTests: XCTestCase {

    override func setUpWithError() throws {
        // Setup before each test
    }

    override func tearDownWithError() throws {
        // Cleanup after each test
    }

    // MARK: - AIToolType Tests

    func testAIToolTypeDisplayNames() throws {
        XCTAssertEqual(AIToolType.claudeCode.displayName, "Claude Code")
        XCTAssertEqual(AIToolType.codex.displayName, "Codex")
        XCTAssertEqual(AIToolType.geminiCLI.displayName, "Gemini CLI")
        XCTAssertEqual(AIToolType.cursor.displayName, "Cursor")
        XCTAssertEqual(AIToolType.openCode.displayName, "OpenCode")
        XCTAssertEqual(AIToolType.droid.displayName, "Droid")
    }

    func testAllAIToolsAreDefined() throws {
        let allTools = AIToolType.allCases
        XCTAssertEqual(allTools.count, 6)
    }

    // MARK: - ToolStatus Tests

    func testToolStatusDescriptions() throws {
        XCTAssertEqual(ToolStatus.online.description, "Online")
        XCTAssertEqual(ToolStatus.busy.description, "Busy")
        XCTAssertEqual(ToolStatus.offline.description, "Offline")
        XCTAssertEqual(ToolStatus.requestingPermission.description, "Permission Request")
    }

    // MARK: - PermissionType Tests

    func testPermissionTypeDisplayNames() throws {
        XCTAssertEqual(PermissionType.fileRead.displayName, "File Read Access")
        XCTAssertEqual(PermissionType.fileWrite.displayName, "File Write Access")
        XCTAssertEqual(PermissionType.networkAccess.displayName, "Network Access")
    }

    // MARK: - Model Tests

    func testAIToolStateInitialization() throws {
        let state = AIToolState(toolType: .claudeCode, status: .online)

        XCTAssertEqual(state.toolType, .claudeCode)
        XCTAssertEqual(state.status, .online)
        XCTAssertNotNil(state.id)
        XCTAssertNotNil(state.lastUpdated)
    }

    func testPermissionRequestInitialization() throws {
        let request = PermissionRequest(
            sourceTool: .claudeCode,
            permissionType: .fileRead,
            details: "Read project files"
        )

        XCTAssertEqual(request.sourceTool, .claudeCode)
        XCTAssertEqual(request.permissionType, .fileRead)
        XCTAssertEqual(request.details, "Read project files")
        XCTAssertNotNil(request.id)
        XCTAssertNotNil(request.timestamp)
    }

    // MARK: - Constants Tests

    func testAppConstants() throws {
        XCTAssertEqual(Constants.App.name, "NotchMind")
        XCTAssertEqual(Constants.App.bundleIdentifier, "com.notchmind.app")
        XCTAssertEqual(Constants.Performance.maxMemoryMB, 50)
    }
}
import XCTest
@testable import NotchMind

final class NotchMindTests: XCTestCase {

    func testAIToolCreation() throws {
        let tool = AITool(name: "claude", type: .claudeCode, status: .idle, isActive: false)

        XCTAssertEqual(tool.name, "claude")
        XCTAssertEqual(tool.type, .claudeCode)
        XCTAssertEqual(tool.status, .idle)
        XCTAssertFalse(tool.isActive)
    }

    func testAIToolTypes() throws {
        let allTypes = AITool.ToolType.allCases

        XCTAssertEqual(allTypes.count, 6)
        XCTAssertTrue(allTypes.contains(.claudeCode))
        XCTAssertTrue(allTypes.contains(.codex))
        XCTAssertTrue(allTypes.contains(.geminiCLI))
        XCTAssertTrue(allTypes.contains(.cursor))
        XCTAssertTrue(allTypes.contains(.openCode))
        XCTAssertTrue(allTypes.contains(.droid))
    }

    func testPermissionRequestCreation() throws {
        let toolId = UUID()
        let request = PermissionRequest(
            toolId: toolId,
            toolName: "Claude Code",
            permissionType: .fileAccess,
            description: "Access project files"
        )

        XCTAssertEqual(request.toolId, toolId)
        XCTAssertEqual(request.toolName, "Claude Code")
        XCTAssertEqual(request.permissionType, .fileAccess)
        XCTAssertEqual(request.status, .pending)
    }

    func testPermissionTypes() throws {
        let allTypes = PermissionRequest.PermissionType.allCases

        XCTAssertEqual(allTypes.count, 6)
        XCTAssertTrue(allTypes.contains(.fileAccess))
        XCTAssertTrue(allTypes.contains(.shellCommand))
        XCTAssertTrue(allTypes.contains(.networkAccess))
        XCTAssertTrue(allTypes.contains(.clipboard))
        XCTAssertTrue(allTypes.contains(.keyboard))
        XCTAssertTrue(allTypes.contains(.processControl))
    }

    func testPermissionRiskLevels() throws {
        XCTAssertEqual(PermissionRequest.PermissionType.fileAccess.riskLevel, .medium)
        XCTAssertEqual(PermissionRequest.PermissionType.shellCommand.riskLevel, .high)
        XCTAssertEqual(PermissionRequest.PermissionType.networkAccess.riskLevel, .low)
    }

    func testAppStateCreation() throws {
        let appState = AppState()

        XCTAssertFalse(appState.isMonitoring)
        XCTAssertTrue(appState.monitoredTools.isEmpty)
        XCTAssertTrue(appState.pendingPermissions.isEmpty)
    }

    func testAppStateToolsInitialized() throws {
        let appState = AppState()

        // After initialization, should have 6 tools
        XCTAssertEqual(appState.monitoredTools.count, 6)
    }
}
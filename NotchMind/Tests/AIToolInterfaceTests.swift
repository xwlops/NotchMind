import XCTest
@testable import NotchMind

final class AIToolInterfaceTests: XCTestCase {

    override func tearDown() async throws {
        let manager = AIToolManager.shared

        for toolId in Array(manager.connectedTools.keys) {
            try? await manager.disconnect(toolId)
        }
    }

    func testAvailableToolsIncludeGitHubCopilotDescriptor() {
        let manager = AIToolManager.shared

        let githubTool = manager.getAvailableTools().first {
            $0.name == "GitHub Copilot" && $0.type == .codex
        }

        XCTAssertNotNil(githubTool)
        XCTAssertEqual(githubTool?.executable, "copilot")
        XCTAssertEqual(githubTool?.supportedFeatures.count, 1)
    }

    func testConnectToGitHubCopilotAndExecutePushCommand() async throws {
        let manager = AIToolManager.shared
        let descriptor = try XCTUnwrap(
            manager.getAvailableTools().first { $0.name == "GitHub Copilot" }
        )

        let tool = try await manager.connect(to: descriptor)
        let response = try await manager.executeCommand("push latest GitHub changes", on: tool.id)

        XCTAssertTrue(tool is GitHubCopilotAdapter)
        XCTAssertTrue(tool.isActive)
        XCTAssertEqual(tool.status, .running)
        XCTAssertEqual(response, "GitHub Copilot response to: push latest GitHub changes")
        XCTAssertTrue(manager.isConnected(tool.id))
    }

    func testGitHubCopilotStatusCallbacksFireOnConnectAndDisconnect() async throws {
        let descriptor = AIToolDescriptor(
            id: UUID(),
            name: "GitHub Copilot",
            type: .codex,
            executable: "copilot",
            supportedFeatures: [.commandExecution]
        )
        let adapter = GitHubCopilotAdapter(descriptor: descriptor)
        var statuses: [AITool.ToolStatus] = []

        adapter.onStatusChange = { statuses.append($0) }

        try await adapter.connect()
        try await adapter.disconnect()

        XCTAssertEqual(statuses, [.running, .idle])
    }

    func testExecuteCommandFailsWhenToolIsNotConnected() async {
        let manager = AIToolManager.shared

        do {
            _ = try await manager.executeCommand("git push", on: UUID())
            XCTFail("Expected toolNotConnected error")
        } catch let error as AIToolError {
            guard case .toolNotConnected = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testDisconnectFailsWhenToolCannotBeFound() async {
        let manager = AIToolManager.shared

        do {
            try await manager.disconnect(UUID())
            XCTFail("Expected toolNotFound error")
        } catch let error as AIToolError {
            guard case .toolNotFound = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testGitHubCopilotDoesNotImplementScriptExecution() async {
        let descriptor = AIToolDescriptor(
            id: UUID(),
            name: "GitHub Copilot",
            type: .codex,
            executable: "copilot",
            supportedFeatures: [.commandExecution]
        )
        let adapter = GitHubCopilotAdapter(descriptor: descriptor)

        do {
            _ = try await adapter.executeScript("echo push")
            XCTFail("Expected notImplemented error")
        } catch let error as AIToolError {
            guard case .notImplemented = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

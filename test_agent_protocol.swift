import Foundation

// Test the AgentProtocol and related classes
func testAgentProtocol() {
    print("Testing AgentProtocol implementation...")

    // Create an instance of ClaudeCodeAgent
    let agent = ClaudeCodeAgent()

    // Test initial properties
    print("Agent ID: \(agent.id)")
    print("Agent Name: \(agent.name)")
    print("Agent Type: \(agent.type.rawValue)")
    print("Initial Status: \(agent.status.rawValue)")
    print("Is Active: \(agent.isActive)")

    // Test initialization
    agent.initialize()
    print("After initialization - Status: \(agent.status.rawValue)")

    // Test starting
    Task {
        do {
            try await agent.start()
            print("After start - Status: \(agent.status.rawValue), Is Active: \(agent.isActive)")

            // Test processing
            let result = try await agent.process(input: "Hello, Claude!")
            print("Process result: \(result)")

            // Test stopping
            try await agent.stop()
            print("After stop - Status: \(agent.status.rawValue), Is Active: \(agent.isActive)")
        } catch {
            print("Error during agent operations: \(error)")
        }
    }

    print("AgentProtocol test completed.")
}

// Run the test
testAgentProtocol()

// Wait a moment for async operations to complete
Thread.sleep(forTimeInterval: 1.0)
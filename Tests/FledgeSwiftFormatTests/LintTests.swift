import Foundation
import Testing

@testable import FledgeSwiftFormat

/// Tests for the LintCommand.
@Suite("Lint Tests")
internal struct LintTests {

    @Test("Lint command runs with correct arguments")
    internal func lintRunsWithCorrectArguments() async throws {
        let mockRunner = MockProcessRunner()
        let command = LintCommand(processRunner: mockRunner)

        try await command.run(
            paths: ["/project/Sources"],
            configPath: "/config/.swift-format.json",
            strict: false
        )

        #expect(mockRunner.lastCommand == "swift-format")
        #expect(mockRunner.lastArguments.contains("lint"))
        #expect(mockRunner.lastArguments.contains("--recursive"))
        #expect(mockRunner.lastArguments.contains("--parallel"))
    }

    @Test("Lint strict adds strict flag")
    internal func lintStrictAddsFlag() async throws {
        let mockRunner = MockProcessRunner()
        let command = LintCommand(processRunner: mockRunner)

        try await command.run(
            paths: ["/project/Sources"],
            configPath: "/config/.swift-format.json",
            strict: true
        )

        #expect(mockRunner.lastArguments.contains("--strict"))
    }

    @Test("Lint strict throws on violations")
    internal func lintStrictThrowsOnViolations() async {
        let mockRunner = MockProcessRunner(exitCode: 1, stdout: "violation found")
        let command = LintCommand(processRunner: mockRunner)

        await #expect(throws: PluginError.self) {
            try await command.run(
                paths: ["/project/Sources"],
                configPath: "/config/.swift-format.json",
                strict: true
            )
        }
    }

    @Test("Lint non-strict does not throw on violations")
    internal func lintNonStrictDoesNotThrow() async throws {
        let mockRunner = MockProcessRunner(exitCode: 1, stdout: "violation found")
        let command = LintCommand(processRunner: mockRunner)

        try await command.run(
            paths: ["/project/Sources"],
            configPath: "/config/.swift-format.json",
            strict: false
        )
    }
}

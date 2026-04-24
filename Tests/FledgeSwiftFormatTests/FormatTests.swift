import Foundation
import Testing

@testable import FledgeSwiftFormat

/// Tests for the FormatCommand.
@Suite("Format Tests")
internal struct FormatTests {

    @Test("Format command runs swift-format with correct arguments")
    internal func formatRunsWithCorrectArguments() async throws {
        let mockRunner = MockProcessRunner()
        let command = FormatCommand(processRunner: mockRunner)

        try await command.run(
            paths: ["/project/Sources"],
            configPath: "/config/.swift-format.json"
        )

        #expect(mockRunner.lastCommand == "swift-format")
        #expect(mockRunner.lastArguments.contains("format"))
        #expect(mockRunner.lastArguments.contains("--in-place"))
        #expect(mockRunner.lastArguments.contains("--recursive"))
        #expect(mockRunner.lastArguments.contains("--parallel"))
        #expect(mockRunner.lastArguments.contains("--configuration"))
        #expect(mockRunner.lastArguments.contains("/config/.swift-format.json"))
        #expect(mockRunner.lastArguments.contains("/project/Sources"))
    }

    @Test("Format command throws on non-zero exit")
    internal func formatThrowsOnFailure() async {
        let mockRunner = MockProcessRunner(exitCode: 1, stderr: "parse error")
        let command = FormatCommand(processRunner: mockRunner)

        await #expect(throws: PluginError.self) {
            try await command.run(
                paths: ["/project/Sources"],
                configPath: "/config/.swift-format.json"
            )
        }
    }
}

/// Tests for Plugin argument parsing.
@Suite("Argument Parsing Tests")
internal struct ArgumentParsingTests {

    @Test("Default mode is format")
    internal func defaultModeIsFormat() async throws {
        let plugin = Plugin()
        let command = try plugin.parseArgumentsForTesting([])

        #expect(command.mode == .format)
        #expect(command.paths.isEmpty)
        #expect(!command.useProjectConfig)
        #expect(!command.strict)
    }

    @Test("Lint flag sets lint mode")
    internal func lintFlagSetsLintMode() async throws {
        let plugin = Plugin()
        let command = try plugin.parseArgumentsForTesting(["--lint"])

        #expect(command.mode == .lint)
    }

    @Test("Check flag sets lint with strict")
    internal func checkFlagSetsLintStrict() async throws {
        let plugin = Plugin()
        let command = try plugin.parseArgumentsForTesting(["--check"])

        #expect(command.mode == .lint)
        #expect(command.strict)
    }

    @Test("Paths are collected")
    internal func pathsAreCollected() async throws {
        let plugin = Plugin()
        let command = try plugin.parseArgumentsForTesting(["Sources", "Tests"])

        #expect(command.paths.count == 2)
        #expect(command.paths.contains("Sources"))
        #expect(command.paths.contains("Tests"))
    }

    @Test("Use project config flag is parsed")
    internal func useProjectConfigFlag() async throws {
        let plugin = Plugin()
        let command = try plugin.parseArgumentsForTesting(["--use-project-config"])

        #expect(command.useProjectConfig)
    }
}

/// A mock process runner for testing.
internal final class MockProcessRunner: ProcessRunner, @unchecked Sendable {

    private(set) var lastCommand: String = ""
    private(set) var lastArguments: [String] = []
    private let exitCode: Int32
    private let stdout: String
    private let stderr: String

    internal init(exitCode: Int32 = 0, stdout: String = "", stderr: String = "") {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }

    internal func run(command: String, arguments: [String]) async throws -> ProcessResult {
        self.lastCommand = command
        self.lastArguments = arguments
        return ProcessResult(
            exitCode: exitCode,
            stdout: stdout,
            stderr: stderr
        )
    }
}

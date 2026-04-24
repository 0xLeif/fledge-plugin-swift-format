import Foundation

/// Executes swift-format in formatting mode.
public struct FormatCommand {

    // MARK: - Properties

    private let processRunner: ProcessRunner

    // MARK: - Initializers

    public init(processRunner: ProcessRunner) {
        self.processRunner = processRunner
    }

    // MARK: - Public Methods

    public func run(paths: [String], configPath: String) async throws {
        var arguments: [String] = [
            "format",
            "--in-place",
            "--recursive",
            "--parallel",
            "--configuration", configPath,
        ]
        arguments.append(contentsOf: paths)

        let result = try await processRunner.run(
            command: "swift-format",
            arguments: arguments
        )

        guard result.exitCode == 0 else {
            throw PluginError.formatFailed(
                exitCode: result.exitCode,
                stderr: result.stderr
            )
        }
    }
}

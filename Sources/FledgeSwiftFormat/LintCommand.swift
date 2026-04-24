import Foundation

/// Executes swift-format in lint mode.
public struct LintCommand {

    // MARK: - Properties

    private let processRunner: ProcessRunner

    // MARK: - Initializers

    public init(processRunner: ProcessRunner) {
        self.processRunner = processRunner
    }

    // MARK: - Public Methods

    public func run(paths: [String], configPath: String, strict: Bool) async throws {
        var arguments: [String] = [
            "lint",
            "--recursive",
            "--parallel",
            "--configuration", configPath,
        ]

        if strict {
            arguments.append("--strict")
        }

        arguments.append(contentsOf: paths)

        let result = try await processRunner.run(
            command: "swift-format",
            arguments: arguments
        )

        if strict && result.exitCode != 0 {
            throw PluginError.formatFailed(
                exitCode: result.exitCode,
                stderr: result.stderr.isEmpty ? result.stdout : result.stderr
            )
        }

        if !strict && !result.stdout.isEmpty {
            if let data = (result.stdout + "\n").data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
        }

        if !result.stderr.isEmpty {
            if let data = (result.stderr + "\n").data(using: .utf8) {
                FileHandle.standardError.write(data)
            }
        }
    }
}

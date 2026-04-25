import Foundation
import Testing

@testable import FledgeSwiftFormat

/// Pipes Swift source through the real `swift-format` binary using the
/// bundled `.swift-format.json` configuration, so integration tests can
/// observe the exact behavior shipped to plugin users.
internal enum SwiftFormatRunner {

    internal enum Mode: String {
        case format
        case lint
    }

    internal struct Result: Sendable {
        internal let exitCode: Int32
        internal let stdout: String
        internal let stderr: String
    }

    internal enum RunnerError: Error, CustomStringConvertible {
        case missingBundledConfig
        case swiftFormatNotInstalled

        internal var description: String {
            switch self {
            case .missingBundledConfig:
                return "Bundled .swift-format.json could not be located in the FledgeSwiftFormat module."
            case .swiftFormatNotInstalled:
                return "swift-format is not on PATH. Install via: brew install swift-format"
            }
        }
    }

    internal static func run(mode: Mode, input: String) async throws -> Result {
        guard let configPath = Plugin.bundledConfigPath else {
            throw RunnerError.missingBundledConfig
        }
        return try await Task.detached {
            try runSync(mode: mode, input: input, configPath: configPath)
        }
        .value
    }

    private static func runSync(mode: Mode, input: String, configPath: String) throws -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "swift-format",
            mode.rawValue,
            "--configuration",
            configPath,
            "-",
        ]

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw RunnerError.swiftFormatNotInstalled
        }

        let normalized = input.hasSuffix("\n") ? input : input + "\n"
        try stdinPipe.fileHandleForWriting.write(contentsOf: Data(normalized.utf8))
        try stdinPipe.fileHandleForWriting.close()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        return Result(
            exitCode: process.terminationStatus,
            stdout: String(decoding: stdoutData, as: UTF8.self),
            stderr: String(decoding: stderrData, as: UTF8.self)
        )
    }
}

/// Runs `swift-format format` over `input` and asserts the result equals `expected`.
internal func assertFormatted(
    input: String,
    equals expected: String,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    let result = try await SwiftFormatRunner.run(mode: .format, input: input)
    #expect(
        result.exitCode == 0,
        "swift-format exited with \(result.exitCode). stderr: \(result.stderr)",
        sourceLocation: sourceLocation
    )
    #expect(
        result.stdout == expected + "\n" || result.stdout == expected,
        """
        Formatted output did not match expected.
        --- expected ---
        \(expected)
        --- got ---
        \(result.stdout)
        """,
        sourceLocation: sourceLocation
    )
}

/// Runs `swift-format lint` over `input` and asserts at least one warning
/// containing the named rule was emitted.
internal func assertLintFinding(
    input: String,
    contains rule: String,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    let result = try await SwiftFormatRunner.run(mode: .lint, input: input)
    let combined = result.stdout + result.stderr
    #expect(
        combined.contains("[\(rule)]"),
        """
        Expected lint warning [\(rule)] but did not find it.
        --- stdout ---
        \(result.stdout)
        --- stderr ---
        \(result.stderr)
        """,
        sourceLocation: sourceLocation
    )
}

/// Runs `swift-format lint` and asserts the named rule was NOT reported.
internal func assertNoLintFinding(
    input: String,
    for rule: String,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    let result = try await SwiftFormatRunner.run(mode: .lint, input: input)
    let combined = result.stdout + result.stderr
    #expect(
        !combined.contains("[\(rule)]"),
        """
        Did not expect lint warning [\(rule)] but it was reported.
        --- stdout ---
        \(result.stdout)
        --- stderr ---
        \(result.stderr)
        """,
        sourceLocation: sourceLocation
    )
}

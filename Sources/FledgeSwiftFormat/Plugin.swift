import Foundation

/// Entry point for the Fledge swift-format plugin.
public struct Plugin {

    // MARK: - Properties

    private let fileManager: FileManager
    private let processRunner: ProcessRunner

    // MARK: - Initializers

    public init(
        fileManager: FileManager = .default,
        processRunner: ProcessRunner = DefaultProcessRunner()
    ) {
        self.fileManager = fileManager
        self.processRunner = processRunner
    }

    // MARK: - Public Methods

    public func run() async throws {
        if isProtocolMode() {
            let handler = ProtocolHandler(plugin: self)
            do {
                try await handler.run()
            } catch ProtocolError.missingInitMessage {
                try await runStandalone()
            }
        } else {
            try await runStandalone()
        }
    }

    public func runStandalone() async throws {
        let arguments = CommandLine.arguments.dropFirst()
        let command = try parseArguments(Array(arguments))
        try await execute(command: command, projectRoot: fileManager.currentDirectoryPath)
    }

    public func execute(command: Command, projectRoot: String) async throws {
        let configPath = try resolveConfigPath(
            command: command,
            projectRoot: projectRoot
        )

        let paths = try resolveTargetPaths(
            command: command,
            projectRoot: projectRoot
        )

        guard !paths.isEmpty else {
            throw PluginError.noSwiftFilesFound
        }

        switch command.mode {
        case .format:
            let formatCommand = FormatCommand(processRunner: processRunner)
            try await formatCommand.run(
                paths: paths,
                configPath: configPath
            )
        case .lint:
            let lintCommand = LintCommand(processRunner: processRunner)
            try await lintCommand.run(
                paths: paths,
                configPath: configPath,
                strict: command.strict
            )
        }
    }

    // MARK: - Private Methods

    private func isProtocolMode() -> Bool {
        guard CommandLine.arguments.count <= 1 else {
            return false
        }
        return isatty(STDIN_FILENO) == 0
    }

    private func parseArguments(_ arguments: [String]) throws -> Command {
        var mode: CommandMode = .format
        var paths: [String] = []
        var useProjectConfig = false
        var strict = false

        var index = 0
        while index < arguments.count {
            let argument = arguments[index]

            switch argument {
            case "--lint", "lint":
                mode = .lint
            case "--check":
                mode = .lint
                strict = true
            case "--use-project-config":
                useProjectConfig = true
            case "--strict":
                strict = true
            case "-h", "--help":
                printHelp()
                exit(0)
            default:
                if !argument.hasPrefix("-") {
                    paths.append(argument)
                } else {
                    throw PluginError.invalidArgument(argument)
                }
            }

            index += 1
        }

        return Command(
            mode: mode,
            paths: paths,
            useProjectConfig: useProjectConfig,
            strict: strict
        )
    }

    private func resolveConfigPath(command: Command, projectRoot: String) throws -> String {
        if command.useProjectConfig {
            return projectRoot
        }

        guard
            let bundledConfigURL = Bundle.module.url(
                forResource: ".swift-format",
                withExtension: "json"
            )
        else {
            throw PluginError.missingBundledConfiguration
        }

        return bundledConfigURL.path
    }

    private func resolveTargetPaths(command: Command, projectRoot: String) throws -> [String] {
        guard command.paths.isEmpty else {
            return command.paths
        }

        let excludedDirectories: Set<String> = [
            ".build",
            "DerivedData",
            ".git",
            ".github",
            "docs",
            "specs",
        ]

        return try discoverSwiftFiles(
            in: projectRoot,
            excluding: excludedDirectories
        )
    }

    private func discoverSwiftFiles(
        in directory: String,
        excluding excluded: Set<String>
    ) throws -> [String] {
        let contents = try fileManager.contentsOfDirectory(atPath: directory)
        var swiftFiles: [String] = []

        for item in contents {
            let itemPath = (directory as NSString).appendingPathComponent(item)
            var isDirectory: ObjCBool = false

            guard
                fileManager.fileExists(
                    atPath: itemPath,
                    isDirectory: &isDirectory
                )
            else {
                continue
            }

            if isDirectory.boolValue {
                guard !excluded.contains(item) else {
                    continue
                }

                let nestedFiles = try discoverSwiftFiles(
                    in: itemPath,
                    excluding: excluded
                )
                swiftFiles.append(contentsOf: nestedFiles)
            } else if item.hasSuffix(".swift") {
                swiftFiles.append(itemPath)
            }
        }

        return swiftFiles
    }

    private func printHelp() {
        print(
            """
            fledge-plugin-swift-format

            Usage:
              fledge swift-format [paths...]          Format Swift files in-place
              fledge swift-format --lint [paths...]     Lint Swift files
              fledge swift-format --check [paths...]    Check formatting without modifying (CI mode)

            Options:
              --lint             Run in lint mode instead of format
              --check            Alias for --lint --strict (exit non-zero on violations)
              --strict           Treat all findings as errors
              --use-project-config  Use the project's own .swift-format file
              -h, --help         Show this help message
            """)
    }
}

// MARK: - Internal Testing Helpers

extension Plugin {
    internal func parseArgumentsForTesting(_ arguments: [String]) throws -> Command {
        try parseArguments(arguments)
    }
}

// MARK: - Supporting Types

/// The mode of operation for the plugin.
public enum CommandMode {
    case format
    case lint
}

/// A parsed command with all options.
public struct Command {
    public let mode: CommandMode
    public let paths: [String]
    public let useProjectConfig: Bool
    public let strict: Bool

    public init(
        mode: CommandMode,
        paths: [String],
        useProjectConfig: Bool,
        strict: Bool
    ) {
        self.mode = mode
        self.paths = paths
        self.useProjectConfig = useProjectConfig
        self.strict = strict
    }
}

/// Errors thrown by the plugin.
public enum PluginError: Error, LocalizedError {
    case invalidArgument(String)
    case missingBundledConfiguration
    case noSwiftFilesFound
    case swiftFormatNotInstalled
    case formatFailed(exitCode: Int32, stderr: String)

    public var errorDescription: String? {
        switch self {
        case .invalidArgument(let argument):
            return "Invalid argument: \(argument)"
        case .missingBundledConfiguration:
            return "Bundled .swift-format.json configuration is missing"
        case .noSwiftFilesFound:
            return "No Swift files found in the current project"
        case .swiftFormatNotInstalled:
            return "swift-format is not installed. Install it via: brew install swift-format"
        case .formatFailed(let exitCode, let stderr):
            return "swift-format exited with code \(exitCode): \(stderr)"
        }
    }
}

/// Protocol for running external processes. Enables testability.
public protocol ProcessRunner: Sendable {
    func run(command: String, arguments: [String]) async throws -> ProcessResult
}

/// The result of running an external process.
public struct ProcessResult: Sendable {
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String

    public init(exitCode: Int32, stdout: String, stderr: String) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }
}

/// Default implementation of ProcessRunner using Process.
public struct DefaultProcessRunner: ProcessRunner {
    public init() {}

    public func run(command: String, arguments: [String]) async throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? ""
        )
    }
}

import Foundation

/// Handles the Fledge v1 JSON-lines protocol for plugin communication.
public struct ProtocolHandler {

    // MARK: - Properties

    private let plugin: Plugin
    private let inputHandle: FileHandle
    private let outputHandle: FileHandle

    // MARK: - Initializers

    public init(
        plugin: Plugin,
        inputHandle: FileHandle = .standardInput,
        outputHandle: FileHandle = .standardOutput
    ) {
        self.plugin = plugin
        self.inputHandle = inputHandle
        self.outputHandle = outputHandle
    }

    // MARK: - Public Methods

    public func run() async throws {
        let initMessage = try readInitMessage()
        let projectRoot = initMessage.project?.root ?? FileManager.default.currentDirectoryPath
        let args = initMessage.args

        send(
            message: ProtocolMessage(
                type: "progress",
                message: "Discovering Swift files",
                current: 1,
                total: 3
            ))

        do {
            let command = try parseProtocolArguments(args)

            send(
                message: ProtocolMessage(
                    type: "progress",
                    message: "Running swift-format",
                    current: 2,
                    total: 3
                ))

            try await plugin.execute(command: command, projectRoot: projectRoot)

            send(
                message: ProtocolMessage(
                    type: "progress",
                    message: "Done",
                    current: 3,
                    total: 3
                ))
            send(message: ProtocolMessage(type: "progress", done: true))

            send(
                message: ProtocolMessage(
                    type: "output",
                    text: command.mode == .format
                        ? "Swift files formatted successfully.\n"
                        : "Swift files linted successfully.\n"
                ))
        } catch {
            send(
                message: ProtocolMessage(
                    type: "progress",
                    done: true
                ))
            send(
                message: ProtocolMessage(
                    type: "log",
                    message: error.localizedDescription,
                    level: "error"
                ))
            send(
                message: ProtocolMessage(
                    type: "output",
                    text: "Error: \(error.localizedDescription)\n"
                ))
            exit(1)
        }
    }

    // MARK: - Private Methods

    private func readInitMessage() throws -> InitMessage {
        let data = inputHandle.availableData
        guard
            !data.isEmpty,
            let line = String(data: data, encoding: .utf8)?.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            !line.isEmpty
        else {
            throw ProtocolError.missingInitMessage
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(InitMessage.self, from: line.data(using: .utf8) ?? Data())
    }

    private func parseProtocolArguments(_ args: [String]) throws -> Command {
        let mode: CommandMode =
            args.contains("--lint") || args.contains("lint") || args.contains("--check")
            ? .lint
            : .format
        let strict = args.contains("--strict") || args.contains("--check")
        let useProjectConfig = args.contains("--use-project-config")
        let paths = args.filter { !$0.hasPrefix("-") }

        return Command(
            mode: mode,
            paths: paths,
            useProjectConfig: useProjectConfig,
            strict: strict
        )
    }

    private func send(message: ProtocolMessage) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .sortedKeys

        guard let data = try? encoder.encode(message),
            let json = String(data: data, encoding: .utf8)
        else {
            return
        }

        if let data = (json + "\n").data(using: .utf8) {
            outputHandle.write(data)
        }
    }
}

// MARK: - Protocol Errors

/// Errors specific to the Fledge protocol handler.
public enum ProtocolError: Error {
    case missingInitMessage
}

// MARK: - Protocol Types

/// The init message sent by fledge to the plugin.
public struct InitMessage: Decodable {
    public let type: String
    public let args: [String]
    public let project: ProjectInfo?

    public struct ProjectInfo: Decodable {
        public let name: String
        public let root: String
        public let language: String?
    }
}

/// An outbound message sent by the plugin to fledge.
public struct ProtocolMessage: Encodable {
    public let type: String
    public var id: String?
    public var message: String?
    public var current: Int?
    public var total: Int?
    public var done: Bool?
    public var level: String?
    public var text: String?

    public init(
        type: String,
        id: String? = nil,
        message: String? = nil,
        current: Int? = nil,
        total: Int? = nil,
        done: Bool? = nil,
        level: String? = nil,
        text: String? = nil
    ) {
        self.type = type
        self.id = id
        self.message = message
        self.current = current
        self.total = total
        self.done = done
        self.level = level
        self.text = text
    }
}

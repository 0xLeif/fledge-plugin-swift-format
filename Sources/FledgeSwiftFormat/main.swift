import Foundation

internal struct FledgeSwiftFormat {
    internal static func main() async throws {
        let plugin = Plugin()
        try await plugin.run()
    }
}

do {
    try await FledgeSwiftFormat.main()
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}

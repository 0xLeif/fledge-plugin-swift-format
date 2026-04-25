import Foundation
import Testing

@testable import FledgeSwiftFormat

/// Integration tests that run the real swift-format binary against horrible
/// Swift code and verify the bundled `.swift-format.json` configuration produces
/// the expected 0xLeif-style output.
@Suite("Bundled Config — Format Behavior")
internal struct BundledConfigFormatTests {

    // MARK: - Indentation

    @Test("Tab indentation is rewritten to 4-space")
    internal func tabsBecomeFourSpaces() async throws {
        let input = """
            public struct Foo {
            \tpublic let value: Int
            }
            """
        let expected = """
            public struct Foo {
                public let value: Int
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Two-space indentation is rewritten to 4-space")
    internal func twoSpaceBecomesFourSpace() async throws {
        let input = """
            public struct Foo {
              public let a: Int
              public func bar() {
                print(a)
              }
            }
            """
        let expected = """
            public struct Foo {
                public let a: Int
                public func bar() {
                    print(a)
                }
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Brace style

    @Test("Allman-style opening braces become K&R")
    internal func allmanBecomesKnR() async throws {
        let input = """
            public struct Foo
            {
                public let value: Int
            }
            """
        let expected = """
            public struct Foo {
                public let value: Int
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Whitespace

    @Test("Multiple blank lines collapse to one")
    internal func multipleBlankLinesCollapse() async throws {
        let input = """
            public struct Foo {
                public let a: Int



                public let b: Int
            }
            """
        let expected = """
            public struct Foo {
                public let a: Int

                public let b: Int
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Argument layout

    @Test("Partially split argument list becomes one-per-line")
    internal func argumentsSplitToOnePerLine() async throws {
        let input = """
            public func makeThing(first: Int,
                second: String, third: Bool) -> String { "" }
            """
        let expected = """
            public func makeThing(
                first: Int,
                second: String,
                third: Bool
            ) -> String { "" }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Imports

    @Test("Imports are sorted and @testable is grouped separately")
    internal func importsAreOrderedAndGrouped() async throws {
        let input = """
            import XCTest
            import Foundation
            import Algorithm
            @testable import MyModule
            """
        let expected = """
            import Algorithm
            import Foundation
            import XCTest

            @testable import MyModule
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Trailing commas / collections

    @Test("Multi-line collections gain trailing commas")
    internal func multiLineCollectionGainsTrailingComma() async throws {
        let input = """
            public let multi = [
                "a",
                "b",
                "c"
            ]
            """
        let expected = """
            public let multi = [
                "a",
                "b",
                "c",
            ]
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Single-line collections stay compact without trailing comma")
    internal func singleLineCollectionStaysCompact() async throws {
        let input = """
            public let things = ["a", "b", "c"]
            """
        try await assertFormatted(input: input, equals: input)
    }

    // MARK: - Statement cleanups

    @Test("Semicolon-separated statements split onto new lines")
    internal func semicolonsBecomeNewlines() async throws {
        let input = """
            public func go() {
                let x = 1; let y = 2
                print(x, y)
            }
            """
        let expected = """
            public func go() {
                let x = 1
                let y = 2
                print(x, y)
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Empty parens before a trailing closure are removed")
    internal func emptyClosureParensRemoved() async throws {
        let input = """
            public func go() {
                runThing(){
                    print("hi")
                }
            }
            public func runThing(_ block: () -> Void) {}
            """
        let expected = """
            public func go() {
                runThing {
                    print("hi")
                }
            }
            public func runThing(_ block: () -> Void) {}
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Multiple variable declarations split onto separate lines")
    internal func multipleVariablesSplit() async throws {
        let input = """
            public func go() {
                var a = 1, b = 2, c = 3
                print(a, b, c)
            }
            """
        let expected = """
            public func go() {
                var a = 1
                var b = 2
                var c = 3
                print(a, b, c)
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Cases with only fallthrough are merged into a comma list")
    internal func fallthroughOnlyCaseIsMerged() async throws {
        let input = """
            public func describe(_ x: Int) -> String {
                switch x {
                case 0:
                    fallthrough
                case 1:
                    return "low"
                default:
                    return "other"
                }
            }
            """
        let expected = """
            public func describe(_ x: Int) -> String {
                switch x {
                case 0, 1:
                    return "low"
                default:
                    return "other"
                }
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Doc comment style (0xLeif hybrid)

    @Test("Triple-slash doc comments for short summaries are preserved")
    internal func shortTripleSlashDocPreserved() async throws {
        let input = """
            /// Short doc.
            public func shortDoc() {}
            """
        try await assertFormatted(input: input, equals: input)
    }

    @Test("Block doc comments for longer descriptions are preserved")
    internal func longBlockDocCommentPreserved() async throws {
        let input = """
            /**
             * Long description that spans
             * multiple lines and explains things
             * in detail.
             */
            public func longDoc() {}
            """
        try await assertFormatted(input: input, equals: input)
    }

    // MARK: - Idempotence

    @Test("Already-clean source is not modified")
    internal func formatIsIdempotent() async throws {
        let input = """
            import Foundation

            public struct Foo {
                public let value: Int

                public init(value: Int) {
                    self.value = value
                }
            }
            """
        try await assertFormatted(input: input, equals: input)
    }
}

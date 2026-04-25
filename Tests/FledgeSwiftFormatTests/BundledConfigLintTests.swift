import Foundation
import Testing

@testable import FledgeSwiftFormat

/// Integration tests that run the real swift-format binary in lint mode and
/// verify the bundled `.swift-format.json` reports the expected 0xLeif-style
/// violations on horrible Swift code.
@Suite("Bundled Config — Lint Findings")
internal struct BundledConfigLintTests {

    // MARK: - Type safety

    @Test("Force unwrap is reported")
    internal func forceUnwrapReported() async throws {
        let input = """
            public func bad(value: Int?) -> Int { value! }
            """
        try await assertLintFinding(input: input, contains: "NeverForceUnwrap")
    }

    @Test("Force try is reported")
    internal func forceTryReported() async throws {
        let input = """
            public func bad() {
                let _ = try! something()
            }
            public func something() throws -> Int { 1 }
            """
        try await assertLintFinding(input: input, contains: "NeverUseForceTry")
    }

    @Test("Implicitly unwrapped optional is reported")
    internal func implicitlyUnwrappedReported() async throws {
        let input = """
            public func bad() {
                let value: Int! = 1
                _ = value
            }
            """
        try await assertLintFinding(input: input, contains: "NeverUseImplicitlyUnwrappedOptionals")
    }

    @Test("Long-form Optional/Array types are reported")
    internal func shorthandTypesReported() async throws {
        let input = """
            public let a: Optional<Int> = nil
            public let b: Array<String> = []
            """
        try await assertLintFinding(input: input, contains: "UseShorthandTypeNames")
    }

    // MARK: - Comments

    @Test("Regular block comments are reported")
    internal func blockCommentReported() async throws {
        let input = """
            public func bad() {
                /* a regular block comment */
                print("hi")
            }
            """
        try await assertLintFinding(input: input, contains: "NoBlockComments")
    }

    @Test("Block doc comments do NOT trigger NoBlockComments")
    internal func blockDocCommentNotReported() async throws {
        let input = """
            /**
             * Documentation block comment.
             * Spans multiple lines.
             */
            public func documented() {}
            """
        try await assertNoLintFinding(input: input, for: "NoBlockComments")
    }

    @Test("Triple-slash docs do NOT trigger UseTripleSlashForDocumentationComments")
    internal func tripleSlashRuleDisabled() async throws {
        let input = """
            /**
             * Documentation block comment.
             * Spans multiple lines.
             */
            public func documented() {}
            """
        try await assertNoLintFinding(input: input, for: "UseTripleSlashForDocumentationComments")
    }

    // MARK: - Naming

    @Test("Type names not in PascalCase are reported")
    internal func typeNamingReported() async throws {
        let input = """
            public struct my_struct {
                public let value: Int
            }
            """
        try await assertLintFinding(input: input, contains: "TypeNamesShouldBeCapitalized")
    }

    @Test("Variable names not in lowerCamelCase are reported")
    internal func variableNamingReported() async throws {
        let input = """
            public struct Foo {
                public let SomeValue: Int
            }
            """
        try await assertLintFinding(input: input, contains: "AlwaysUseLowerCamelCase")
    }

    // MARK: - Structure

    @Test("Access level on extension is reported")
    internal func accessLevelOnExtensionReported() async throws {
        let input = """
            public extension String {
                func shout() -> String { uppercased() }
            }
            """
        try await assertLintFinding(input: input, contains: "NoAccessLevelOnExtensionDeclaration")
    }

    @Test("Parens around if/while conditions are reported")
    internal func parensAroundConditionsReported() async throws {
        let input = """
            public func go(x: Int) {
                if (x > 0) {
                    print(x)
                }
            }
            """
        try await assertLintFinding(input: input, contains: "NoParensAroundConditions")
    }

    @Test("Explicit Void return type is reported")
    internal func voidReturnReported() async throws {
        let input = """
            public func nothing() -> Void {
                print("hi")
            }
            """
        try await assertLintFinding(input: input, contains: "NoVoidReturnOnFunctionSignature")
    }

    @Test("Empty trailing closure parens are reported")
    internal func emptyClosureParensReported() async throws {
        let input = """
            public func go() {
                runThing(){
                    print("hi")
                }
            }
            public func runThing(_ block: () -> Void) {}
            """
        try await assertLintFinding(input: input, contains: "NoEmptyTrailingClosureParentheses")
    }

    @Test("Multiple variable declarations on one line are reported")
    internal func oneVariableDeclarationReported() async throws {
        let input = """
            public func go() {
                var a = 1, b = 2
                print(a, b)
            }
            """
        try await assertLintFinding(input: input, contains: "OneVariableDeclarationPerLine")
    }

    @Test("Cases that only fall through are reported")
    internal func fallthroughOnlyReported() async throws {
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
        try await assertLintFinding(input: input, contains: "NoCasesWithOnlyFallthrough")
    }

    @Test("Unsorted imports are reported")
    internal func orderedImportsReported() async throws {
        let input = """
            import XCTest
            import Foundation
            """
        try await assertLintFinding(input: input, contains: "OrderedImports")
    }

    @Test("Semicolons at the end of statements are reported")
    internal func semicolonsReported() async throws {
        let input = """
            public func go() {
                let x = 1;
                print(x)
            }
            """
        try await assertLintFinding(input: input, contains: "DoNotUseSemicolons")
    }

    // MARK: - Negative cases

    @Test("Clean code produces no lint findings")
    internal func cleanCodeProducesNoFindings() async throws {
        let input = """
            import Foundation

            public struct Foo {
                public let value: Int

                public init(value: Int) {
                    self.value = value
                }
            }
            """
        let result = try await SwiftFormatRunner.run(mode: .lint, input: input)
        let combined = result.stdout + result.stderr
        #expect(
            combined.isEmpty,
            """
            Expected no lint output for clean code, got:
            --- stdout ---
            \(result.stdout)
            --- stderr ---
            \(result.stderr)
            """
        )
    }
}

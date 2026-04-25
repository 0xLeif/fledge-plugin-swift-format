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

    @Test("Force cast (as!) is reported")
    internal func forceCastReported() async throws {
        let input = """
            public func bad(_ x: Any) -> Int {
                let v = x as! Int
                return v
            }
            """
        try await assertLintFinding(input: input, contains: "NeverForceUnwrap")
    }

    @Test("try? does NOT trigger NeverUseForceTry")
    internal func optionalTryAllowed() async throws {
        let input = """
            public func go() throws -> Int { 1 }
            public func use() {
                let x = try? go()
                print(x as Any)
            }
            """
        try await assertNoLintFinding(input: input, for: "NeverUseForceTry")
    }

    @Test("Optional cast (as?) does NOT trigger NeverForceUnwrap")
    internal func optionalCastAllowed() async throws {
        let input = """
            public func go(_ x: Any) -> Int? {
                x as? Int
            }
            """
        try await assertNoLintFinding(input: input, for: "NeverForceUnwrap")
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

    // MARK: - Iteration / collection patterns

    @Test("forEach is reported in favor of for-in")
    internal func forEachReported() async throws {
        let input = """
            public func go(_ items: [Int]) {
                items.forEach { item in
                    print(item)
                }
            }
            """
        try await assertLintFinding(input: input, contains: "ReplaceForEachWithForLoop")
    }

    // MARK: - Numeric literals

    @Test("Decimal literals over 999 are reported for missing _ separator")
    internal func decimalLiteralGroupingReported() async throws {
        let input = """
            public let big = 1000000
            """
        try await assertLintFinding(input: input, contains: "GroupNumericLiterals")
    }

    @Test("Hex literals over 4 digits are reported for missing _ separator")
    internal func hexLiteralGroupingReported() async throws {
        let input = """
            public let mask = 0xFFFFFFFF
            """
        try await assertLintFinding(input: input, contains: "GroupNumericLiterals")
    }

    // MARK: - Properties / initializers

    @Test("Manual single-key get { } in computed property is reported")
    internal func manualGetterIsReported() async throws {
        let input = """
            public struct Foo {
                public var x: Int {
                    get {
                        return 42
                    }
                }
            }
            """
        try await assertLintFinding(input: input, contains: "UseSingleLinePropertyGetter")
    }

    @Test("Static property names that repeat the type are reported")
    internal func dontRepeatTypeInStaticPropertyReported() async throws {
        let input = """
            public struct Color {
                public static let redColor = Color()
                public static let blueColor = Color()
            }
            """
        try await assertLintFinding(input: input, contains: "DontRepeatTypeInStaticProperties")
    }

    @Test("Manual init that matches synthesized memberwise init is reported")
    internal func synthesizedInitReported() async throws {
        let input = """
            internal struct Point {
                internal let x: Int
                internal let y: Int

                internal init(x: Int, y: Int) {
                    self.x = x
                    self.y = y
                }
            }
            """
        try await assertLintFinding(input: input, contains: "UseSynthesizedInitializer")
    }

    // MARK: - Pattern matching

    @Test("Mixing 'case let' and 'case ... let' patterns is reported")
    internal func letInEveryBoundCaseReported() async throws {
        let input = """
            public func go(_ x: Result<Int, Error>) {
                switch x {
                case .success(let value):
                    print(value)
                case let .failure(error):
                    print(error)
                }
            }
            """
        try await assertLintFinding(input: input, contains: "UseLetInEveryBoundCaseVariable")
    }

    @Test("Optional binding that discards the value is reported")
    internal func explicitNilCheckReported() async throws {
        let input = """
            public func go(_ x: Int?) {
                if let _ = x {
                    print("set")
                }
            }
            """
        try await assertLintFinding(input: input, contains: "UseExplicitNilCheckInConditions")
    }

    // MARK: - Type signatures

    @Test("Empty tuple in return position is reported")
    internal func emptyTupleReturnReported() async throws {
        let input = """
            public typealias Handler = () -> ()
            """
        try await assertLintFinding(input: input, contains: "ReturnVoidInsteadOfEmptyTuple")
    }

    // MARK: - Enums

    @Test("Enum where every case is indirect is reported")
    internal func fullyIndirectEnumReported() async throws {
        let input = """
            public enum Tree {
                indirect case node(Int, Tree, Tree)
                indirect case leaf(Int)
            }
            """
        try await assertLintFinding(input: input, contains: "FullyIndirectEnum")
    }

    @Test("Enum cases with raw values on one line are reported")
    internal func oneCasePerLineReported() async throws {
        let input = """
            public enum Color: Int {
                case red = 1, green = 2, blue = 3
            }
            """
        try await assertLintFinding(input: input, contains: "OneCasePerLine")
    }

    // MARK: - Identifiers

    @Test("Non-ASCII identifiers are reported")
    internal func nonAsciiIdentifierReported() async throws {
        let input = """
            public let café = "coffee"
            """
        try await assertLintFinding(input: input, contains: "IdentifiersMustBeASCII")
    }

    // MARK: - Expressions

    @Test("Assignment used as a sub-expression is reported")
    internal func assignmentInExpressionReported() async throws {
        let input = """
            public func go() {
                var x = 0
                let y = (x = 5)
                print(x, y)
            }
            """
        try await assertLintFinding(input: input, contains: "NoAssignmentInExpressions")
    }

    // MARK: - Conformances

    @Test("@retroactive conformance is reported")
    internal func retroactiveConformanceReported() async throws {
        let input = """
            extension String: @retroactive Identifiable {
                public var id: String { self }
            }
            """
        try await assertLintFinding(input: input, contains: "AvoidRetroactiveConformances")
    }

    @Test("Overloads ambiguous when called with a trailing closure are reported")
    internal func ambiguousTrailingClosureReported() async throws {
        let input = """
            public struct Foo {
                public func run(_ block: () -> Void) {}
                public func run(_ block: () -> Int) {}
            }
            """
        try await assertLintFinding(input: input, contains: "AmbiguousTrailingClosureOverload")
    }

    @Test("Playground literals are reported")
    internal func playgroundLiteralReported() async throws {
        let input = """
            import UIKit
            public let c = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
            """
        try await assertLintFinding(input: input, contains: "NoPlaygroundLiterals")
    }

    @Test("Redundant labels in case patterns are reported")
    internal func labelsInCasePatternsReported() async throws {
        let input = """
            public enum Shape { case point(x: Int, y: Int) }
            public func describe(_ s: Shape) -> String {
                switch s {
                case .point(x: let x, y: let y):
                    return "\\(x),\\(y)"
                }
            }
            """
        try await assertLintFinding(input: input, contains: "NoLabelsInCasePatterns")
    }

    // MARK: - Negative cases for disabled rules

    @Test("Leading underscore identifier does NOT trigger NoLeadingUnderscores")
    internal func leadingUnderscoreAllowed() async throws {
        let input = """
            public struct Foo {
                private let _internal: Int = 0
            }
            """
        try await assertNoLintFinding(input: input, for: "NoLeadingUnderscores")
    }

    @Test("Explicit return does NOT trigger OmitExplicitReturns")
    internal func explicitReturnNotReported() async throws {
        let input = """
            public func compute() -> Int {
                return 42
            }
            public var x: Int { return 42 }
            """
        try await assertNoLintFinding(input: input, for: "OmitExplicitReturns")
    }

    @Test("if/else without early-exit conversion does NOT trigger UseEarlyExits")
    internal func earlyExitsNotReported() async throws {
        let input = """
            public func go(_ x: Int) -> Int {
                if x > 0 {
                    return 1
                } else {
                    return 2
                }
            }
            """
        try await assertNoLintFinding(input: input, for: "UseEarlyExits")
    }

    @Test("for-in with conditional body does NOT trigger UseWhereClausesInForLoops")
    internal func whereClauseNotReported() async throws {
        let input = """
            public func go(_ items: [Int]) {
                for item in items {
                    if item > 0 {
                        print(item)
                    }
                }
            }
            """
        try await assertNoLintFinding(input: input, for: "UseWhereClausesInForLoops")
    }

    @Test("Undocumented public declarations do NOT trigger AllPublicDeclarationsHaveDocumentation")
    internal func undocumentedPublicAllowed() async throws {
        let input = """
            public func undocumented() {}
            public struct Bare { public let x: Int }
            """
        try await assertNoLintFinding(input: input, for: "AllPublicDeclarationsHaveDocumentation")
    }

    @Test("Mismatched parameter docs do NOT trigger ValidateDocumentationComments")
    internal func mismatchedParamDocAllowed() async throws {
        let input = """
            /// Brief.
            /// - Parameter wrong: doesn't exist on the function.
            /// - Returns: nothing.
            public func go(actual: Int) {}
            """
        try await assertNoLintFinding(input: input, for: "ValidateDocumentationComments")
    }

    @Test("Multi-sentence first line of doc comment does NOT trigger BeginDocumentationCommentWithOneLineSummary")
    internal func multiSentenceDocAllowed() async throws {
        let input = """
            /// This is a doc comment that is a single very long sentence and does not have a summary period.
            public func go() {}
            """
        try await assertNoLintFinding(input: input, for: "BeginDocumentationCommentWithOneLineSummary")
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

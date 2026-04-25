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

    // MARK: - Mixed / weird indentation

    @Test("Mixed tab + 2-space + 4-space indent is normalized to 4-space")
    internal func mixedIndentationNormalized() async throws {
        let input = """
            public struct Foo {
            \tpublic let a: Int
                public let b: Int
              public let c: Int
            }
            """
        let expected = """
            public struct Foo {
                public let a: Int
                public let b: Int
                public let c: Int
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Trailing whitespace on a line is removed")
    internal func trailingWhitespaceRemoved() async throws {
        let input = "public let x = 1   \npublic let y = 2"
        let expected = "public let x = 1\npublic let y = 2"
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Switch / conditional compilation

    @Test("Switch case labels are not extra-indented")
    internal func switchCaseLabelsAlignWithSwitch() async throws {
        let input = """
            public func go(_ x: Int) {
                switch x {
                    case 1:
                        print("one")
                    default:
                        print("other")
                }
            }
            """
        let expected = """
            public func go(_ x: Int) {
                switch x {
                case 1:
                    print("one")
                default:
                    print("other")
                }
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Conditional compilation block bodies are indented")
    internal func conditionalCompilationBodiesIndented() async throws {
        let input = """
            public func go() {
            #if os(macOS)
            print("mac")
            #else
            print("other")
            #endif
            }
            """
        let expected = """
            public func go() {
                #if os(macOS)
                    print("mac")
                #else
                    print("other")
                #endif
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Operators / spacing

    @Test("Spaces around range operators are removed")
    internal func rangeOperatorsHaveNoSpaces() async throws {
        let input = """
            public let r = 1 ... 10
            public let half = 1 ..< 10
            """
        let expected = """
            public let r = 1...10
            public let half = 1..<10
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("End-of-line comments get exactly two spaces of separation")
    internal func endOfLineCommentSpacingNormalized() async throws {
        let input = """
            public let x = 1 // one space
            public let y = 2  // two spaces
            public let z = 3// no space
            """
        let expected = """
            public let x = 1  // one space
            public let y = 2  // two spaces
            public let z = 3  // no space
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Property accessors

    @Test("Single-line property getter strips the get { } wrapper")
    internal func singleLinePropertyGetterStrippedFromBlock() async throws {
        let input = """
            public struct Foo {
                public var x: Int {
                    get {
                        return 42
                    }
                }
            }
            """
        let expected = """
            public struct Foo {
                public var x: Int {
                    return 42
                }
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Enum case layout

    @Test("Enum cases with raw values split onto their own lines")
    internal func enumCasesWithRawValuesSplit() async throws {
        let input = """
            public enum Color: Int {
                case red = 1, green = 2, blue = 3
            }
            """
        let expected = """
            public enum Color: Int {
                case red = 1
                case green = 2
                case blue = 3
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Enum cases with associated values split onto their own lines")
    internal func enumCasesWithAssociatedValuesSplit() async throws {
        let input = """
            public enum Shape {
                case circle(radius: Double), square(side: Double)
            }
            """
        let expected = """
            public enum Shape {
                case circle(radius: Double)
                case square(side: Double)
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Bare enum cases (no raw or associated values) stay on one line")
    internal func bareEnumCasesStayOnOneLine() async throws {
        let input = """
            public enum Status {
                case red, green, blue
            }
            """
        try await assertFormatted(input: input, equals: input)
    }

    // MARK: - Generics & wrapping

    @Test("Long generic function signature wraps args one-per-line")
    internal func longGenericSignatureWraps() async throws {
        let input = """
            public func merge<LeftOutput, RightOutput, Output>(left: LeftOutput, right: RightOutput, transform: (LeftOutput, RightOutput) -> Output) -> Output where LeftOutput: Sendable, RightOutput: Sendable, Output: Sendable {
                transform(left, right)
            }
            """
        let expected = """
            public func merge<LeftOutput, RightOutput, Output>(
                left: LeftOutput,
                right: RightOutput,
                transform: (LeftOutput, RightOutput) -> Output
            ) -> Output where LeftOutput: Sendable, RightOutput: Sendable, Output: Sendable {
                transform(left, right)
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Multi-line strings

    @Test("Multi-line string literals are preserved verbatim")
    internal func multiLineStringLiteralPreserved() async throws {
        let input = """
            public let banner = \"\"\"
                line one
                line two with extra        spacing
                line three
                \"\"\"
            """
        try await assertFormatted(input: input, equals: input)
    }

    // MARK: - Disabled rules — explicit returns must be left intact

    @Test("Explicit return is preserved (OmitExplicitReturns disabled)")
    internal func explicitReturnPreserved() async throws {
        let input = """
            public func compute() -> Int {
                return 42
            }
            """
        try await assertFormatted(input: input, equals: input)
    }

    @Test("Explicit return in computed property body is preserved")
    internal func explicitReturnInComputedPropertyPreserved() async throws {
        let input = """
            public struct Foo {
                public var x: Int {
                    return 42
                }
            }
            """
        try await assertFormatted(input: input, equals: input)
    }

    // MARK: - Token spacing

    @Test("Binary operators get one space on each side")
    internal func binaryOperatorSpacingNormalized() async throws {
        let input = """
            public let a = 1+2
            public let b = 1   +   2
            public let c = a*2-1
            """
        let expected = """
            public let a = 1 + 2
            public let b = 1 + 2
            public let c = a * 2 - 1
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Colons get no space before and one space after")
    internal func colonSpacingNormalized() async throws {
        let input = """
            public struct Foo {
                public let value : Int
                public let dict : [String : Int]
            }
            """
        let expected = """
            public struct Foo {
                public let value: Int
                public let dict: [String: Int]
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Commas get no space before and one space after")
    internal func commaSpacingNormalized() async throws {
        let input = """
            public func go(x:Int,y:Int,z:Int){print(x,y,z)}
            """
        let expected = """
            public func go(x: Int, y: Int, z: Int) { print(x, y, z) }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Excess whitespace inside parentheses is collapsed")
    internal func parenInteriorWhitespaceCollapsed() async throws {
        let input = """
            public func go(  x: Int  ,  y: Int  )  {  print(x, y)  }
            """
        let expected = """
            public func go(x: Int, y: Int) { print(x, y) }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Closure call sites

    @Test("Trailing closure call site is normalized for spacing and arguments")
    internal func trailingClosureCallSiteNormalized() async throws {
        let input = """
            public let doubled = [1,2,3].map{$0*2}
            """
        let expected = """
            public let doubled = [1, 2, 3].map { $0 * 2 }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Closure with capture list is preserved")
    internal func closureWithCaptureListPreserved() async throws {
        let input = """
            public class Foo {
                public func go() {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        self.doStuff()
                    }
                }
                public func doStuff() {}
            }
            """
        try await assertFormatted(input: input, equals: input)
    }

    // MARK: - Modern Swift syntax

    @Test("async let is preserved")
    internal func asyncLetPreserved() async throws {
        let input = """
            public func merge() async throws -> (Int, String) {
                async let a = fetchInt()
                async let b = fetchString()
                return try await (a, b)
            }
            public func fetchInt() async -> Int { 1 }
            public func fetchString() async -> String { "" }
            """
        try await assertFormatted(input: input, equals: input)
    }

    @Test("willSet/didSet observers are preserved")
    internal func propertyObserversPreserved() async throws {
        let input = """
            public class Bar {
                public var x: Int = 0 {
                    willSet {
                        print("will", newValue)
                    }
                    didSet {
                        print("did", oldValue)
                    }
                }
            }
            """
        try await assertFormatted(input: input, equals: input)
    }

    @Test("Property wrapper attributes are preserved")
    internal func propertyWrappersPreserved() async throws {
        let input = """
            @MainActor
            public final class Foo {
                @Published public var x: Int = 0
                @MainActor public func bar() {
                    print(x)
                }
            }
            """
        try await assertFormatted(input: input, equals: input)
    }

    @Test("some/any existential types are preserved")
    internal func opaqueAndExistentialPreserved() async throws {
        let input = """
            public protocol Shape {}
            public struct Circle: Shape {}
            public func makeShape() -> some Shape { Circle() }
            public func acceptShape(_ shape: any Shape) {}
            """
        try await assertFormatted(input: input, equals: input)
    }

    @Test("@resultBuilder declarations are preserved")
    internal func resultBuilderPreserved() async throws {
        let input = """
            @resultBuilder
            public struct StringBuilder {
                public static func buildBlock(_ parts: String...) -> String { parts.joined() }
            }
            public func makeText(@StringBuilder _ build: () -> String) -> String { build() }
            """
        try await assertFormatted(input: input, equals: input)
    }

    @Test("#available checks are preserved")
    internal func availabilityCheckPreserved() async throws {
        let input = """
            public func newApi() {
                if #available(iOS 16, *) {
                    print("modern")
                }
            }
            """
        try await assertFormatted(input: input, equals: input)
    }

    // MARK: - Whole-decl-on-one-line explosion

    @Test("Entire struct crammed onto one line is exploded onto multiple lines")
    internal func structOnOneLineExplodes() async throws {
        let input = """
            public struct Foo { public let value: Int; public func bar() -> Int { value } }
            """
        let expected = """
            public struct Foo {
                public let value: Int
                public func bar() -> Int { value }
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Multiple top-level declarations joined by ; split onto separate lines")
    internal func semicolonJoinedTopLevelDeclsSplit() async throws {
        let input = """
            public func a() {}; public func b() {}; public func c() {}
            """
        let expected = """
            public func a() {}
            public func b() {}
            public func c() {}
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Massive struct with init body all on one line is fully expanded")
    internal func massiveStructOnOneLineExplodes() async throws {
        let input = """
            public struct User { public let name: String; public let age: Int; public let email: String; public init(name: String, age: Int, email: String) { self.name = name; self.age = age; self.email = email } }
            """
        let expected = """
            public struct User {
                public let name: String
                public let age: Int
                public let email: String
                public init(name: String, age: Int, email: String) {
                    self.name = name
                    self.age = age
                    self.email = email
                }
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Long single-line function with body exceeding 120 chars wraps the body")
    internal func longSingleLineFunctionWraps() async throws {
        let input = """
            public func greet(name: String, age: Int) -> String { return "Hello, " + name + " you are " + String(age) + " years old today!" }
            """
        let expected = """
            public func greet(name: String, age: Int) -> String {
                return "Hello, " + name + " you are " + String(age) + " years old today!"
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Enum with all cases joined by ; on one line splits each case onto its own line")
    internal func enumWithSemicolonJoinedCasesSplits() async throws {
        let input = """
            public enum Day { case monday; case tuesday; case wednesday; case thursday; case friday; case saturday; case sunday }
            """
        let expected = """
            public enum Day {
                case monday
                case tuesday
                case wednesday
                case thursday
                case friday
                case saturday
                case sunday
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    @Test("Nested struct crammed on one line is fully exploded")
    internal func nestedStructOnOneLineExplodes() async throws {
        let input = """
            public struct Outer { public struct Inner { public let x: Int; public let y: Int }; public let value: Inner; public func sum() -> Int { value.x + value.y } }
            """
        let expected = """
            public struct Outer {
                public struct Inner {
                    public let x: Int
                    public let y: Int
                }
                public let value: Inner
                public func sum() -> Int { value.x + value.y }
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }

    // MARK: - Stress integration

    @Test("Horrible-but-mechanically-fixable code is fully cleaned in one pass")
    internal func horribleFileIsCompletelyFixed() async throws {
        let input = """
            import XCTest
            import Foundation

            public class Foo
            {
            \tpublic let value : Int
              public let pairs : [String : Int] = [:]
              public func doStuff(  x:Int  ,y:Int)  {
                if (x>0){
                  print("positive");print(y);
                }
                var a = 1, b = 2
                let _ = a; let _ = b
              }

              public init(value : Int){self.value=value}
            }
            """
        let expected = """
            import Foundation
            import XCTest

            public class Foo {
                public let value: Int
                public let pairs: [String: Int] = [:]
                public func doStuff(x: Int, y: Int) {
                    if x > 0 {
                        print("positive")
                        print(y)
                    }
                    var a = 1
                    var b = 2
                    let _ = a
                    let _ = b
                }

                public init(value: Int) { self.value = value }
            }
            """
        try await assertFormatted(input: input, equals: expected)
    }
}

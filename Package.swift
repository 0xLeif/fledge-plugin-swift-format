// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "FledgeSwiftFormat",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "fledge-plugin-swift-format",
            targets: ["FledgeSwiftFormat"]
        )
    ],
    targets: [
        .executableTarget(
            name: "FledgeSwiftFormat",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "FledgeSwiftFormatTests",
            dependencies: ["FledgeSwiftFormat"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)

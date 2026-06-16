// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ComparisonCore",
    products: [
        // The engine — imported by the app later.
        .library(name: "ComparisonCore", targets: ["ComparisonCore"]),
        // A thin CLI to exercise the engine without the app.
        .executable(name: "comparison-cli", targets: ["ComparisonCLI"]),
    ],
    targets: [
        .target(name: "ComparisonCore"),
        .executableTarget(
            name: "ComparisonCLI",
            dependencies: ["ComparisonCore"]
        ),
        .testTarget(
            name: "ComparisonCoreTests",
            dependencies: ["ComparisonCore"]
        ),
    ]
)

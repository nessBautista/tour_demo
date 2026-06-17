// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EventLog",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
    ],
    products: [
        .library(name: "EventLog", targets: ["EventLog"]),
    ],
    targets: [
        .target(name: "EventLog"),
        .testTarget(name: "EventLogTests", dependencies: ["EventLog"]),
    ]
)

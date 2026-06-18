// swift-tools-version:6.0
import PackageDescription

// AgentKit — a small, domain-agnostic ReAct / emit-tools agent kernel.
//
// Foundation-only and zero app dependencies, so it builds and unit-tests in the
// Linux container (stub reasoner, no network) and links into the iOS app alike.
// The app supplies the LLM key + a per-feature "palette" (tool schemas + prompts
// + an `apply` dispatcher); the kernel runs the loop. Ported from the EXP-001
// extraction-harness probe (itself a fork of Lab-002 ReActKit), which proved the
// design live across multiple model vendors.
let package = Package(
    name: "agent-kit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "AgentKit", targets: ["AgentKit"]),
    ],
    targets: [
        .target(name: "AgentKit"),
        .testTarget(name: "AgentKitTests", dependencies: ["AgentKit"]),
    ]
)

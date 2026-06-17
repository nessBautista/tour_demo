// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceExtraction",
    platforms: [
        // The on-device transcription pipeline targets iOS 26 (SpeechAnalyzer).
        .iOS(.v17),
        // The pure parts (LocaleResolver, models, stub) build & test on macOS;
        // the iOS-only Apple code is #if os(iOS)-excluded there.
        // macOS 14 / iOS 17 floor: the @Observable Observation framework.
        .macOS(.v14),
    ],
    products: [
        .library(name: "VoiceExtraction", targets: ["VoiceExtraction"]),
    ],
    targets: [
        .target(name: "VoiceExtraction"),
        .testTarget(
            name: "VoiceExtractionTests",
            dependencies: ["VoiceExtraction"]
        ),
    ]
)

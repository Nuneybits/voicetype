// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VoiceType",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1"),
    ],
    targets: [
        .executableTarget(
            name: "VoiceType",
            dependencies: [
                "WhisperKit",
                "HotKey",
            ],
            path: "Sources/VoiceType",
            exclude: ["Resources/.gitkeep"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        // Tests require full Xcode (not just Command Line Tools)
        // Uncomment when Xcode is installed:
        // .testTarget(
        //     name: "VoiceTypeTests",
        //     dependencies: ["VoiceType"],
        //     path: "Tests/VoiceTypeTests",
        //     swiftSettings: [
        //         .swiftLanguageMode(.v5),
        //     ]
        // ),
    ]
)

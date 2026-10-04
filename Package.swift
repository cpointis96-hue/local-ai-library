// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalAILibrary",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "LocalAILibrary", targets: ["LocalAILibrary"]),
    ],
    targets: [
        .executableTarget(
            name: "LocalAILibrary",
            path: "Sources/LocalAILibrary",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "LocalAILibraryTests",
            dependencies: ["LocalAILibrary"],
            path: "Tests/LocalAILibraryTests"
        ),
    ]
)

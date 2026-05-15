// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FocusForgeCoachEngine",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
    ],
    products: [
        .library(
            name: "FocusForgeCoachEngine",
            targets: ["FocusForgeCoachEngine"]
        ),
    ],
    targets: [
        .target(
            name: "FocusForgeCoachEngine",
            path: "Sources/FocusForgeCoachEngine"
        ),
        .testTarget(
            name: "FocusForgeCoachEngineTests",
            dependencies: ["FocusForgeCoachEngine"],
            path: "Tests/FocusForgeCoachEngineTests"
        ),
    ]
)

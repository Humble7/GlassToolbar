// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GlassToolbar",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "GlassToolbar",
            targets: ["GlassToolbar"]
        ),
    ],
    targets: [
        .target(
            name: "GlassToolbar",
            path: "Sources/GlassToolbar",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "GlassToolbarTests",
            dependencies: ["GlassToolbar"],
            path: "Tests/GlassToolbarTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)

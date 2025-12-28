// swift-tools-version: 5.9
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
            path: "Sources/GlassToolbar"
        ),
        .testTarget(
            name: "GlassToolbarTests",
            dependencies: ["GlassToolbar"],
            path: "Tests/GlassToolbarTests"
        ),
    ]
)

// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWPuzzleBoardView",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "WWPuzzleBoardView", targets: ["WWPuzzleBoardView"]),
    ],
    targets: [
        .target(name: "WWPuzzleBoardView", resources: [.copy("Privacy")]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)

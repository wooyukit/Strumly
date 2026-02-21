// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "StrumlyUI",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "StrumlyUI",
            targets: ["StrumlyUI"]
        ),
    ],
    dependencies: [
        .package(path: "../StrumlyCore"),
    ],
    targets: [
        .target(
            name: "StrumlyUI",
            dependencies: ["StrumlyCore"]
        ),
        .testTarget(
            name: "StrumlyUITests",
            dependencies: ["StrumlyUI"]
        ),
    ]
)

// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "StrumlyCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "StrumlyCore",
            targets: ["StrumlyCore"]
        ),
    ],
    targets: [
        .target(
            name: "StrumlyCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "StrumlyCoreTests",
            dependencies: ["StrumlyCore"]
        ),
    ]
)

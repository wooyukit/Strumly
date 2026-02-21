// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "StrumlyTuner",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "StrumlyTuner",
            targets: ["StrumlyTuner"]
        ),
    ],
    targets: [
        .target(
            name: "StrumlyTuner"
        ),
        .testTarget(
            name: "StrumlyTunerTests",
            dependencies: ["StrumlyTuner"]
        ),
    ]
)

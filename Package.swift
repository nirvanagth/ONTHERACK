// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ONTHERACK",
    platforms: [
        .iOS(.v18)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ONTHERACK",
            path: "ONTHERACK",
            resources: [
                .process("Resources"),
                .process("Info.plist"),
            ]
        ),
    ]
)

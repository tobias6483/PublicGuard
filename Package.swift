// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PublicGuard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "PublicGuard", targets: ["PublicGuard"])
    ],
    targets: [
        .executableTarget(
            name: "PublicGuard",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("IOKit"),
                .linkedFramework("LocalAuthentication"),
                .linkedFramework("UserNotifications")
            ]
        ),
        .testTarget(
            name: "PublicGuardTests",
            dependencies: ["PublicGuard"]
        )
    ]
)

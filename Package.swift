// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SecureProxySDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "SecureProxySDK",
            targets: ["SecureProxySDK"]
        ),
    ],
    targets: [
        .target(
            name: "SecureProxySDK",
            dependencies: []
        ),
        .testTarget(
            name: "SecureProxySDKTests",
            dependencies: ["SecureProxySDK"]
        ),
    ]
)

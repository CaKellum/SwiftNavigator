// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyNavigation",
    platforms: [.iOS(.v26)],
    products: [.library(name: "SwiftyNavigation", targets: ["SwiftyNavigation"])],
    targets: [
        .target(name: "SwiftyNavigation"),
        .testTarget(name: "SwiftyNavigationTests", dependencies: ["SwiftyNavigation"]),
    ]
)

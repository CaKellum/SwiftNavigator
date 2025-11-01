// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyNavigation",
    platforms: [.iOS(.v26)],
    products: [.library(name: "SwiftyNavigation", targets: ["SwiftyNavigation"])],
    dependencies: [.package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.62.0")],
    targets: [
        .target(name: "SwiftyNavigation",
                plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]),
        .testTarget(name: "SwiftyNavigationTests", dependencies: ["SwiftyNavigation"]),
    ]
)

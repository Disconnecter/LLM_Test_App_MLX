// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MLXServicePackage",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MLXServicePackage",
            targets: ["MLXServicePackage"],

        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift-lm/", .upToNextMinor(from: "2.30.6"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MLXServicePackage",
            dependencies: [
                .product(name: "MLXLLM", package: "mlx-swift-lm")
            ]
        )
        ,
        .testTarget(
            name: "MLXServicePackageTests",
            dependencies: ["MLXServicePackage"]
        ),
    ]
)

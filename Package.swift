// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "postgresql-swift",
    products: [
        .library(name: "postgresql-swift", targets: ["postgresql-swift"]),
        .executable(name: "example-1", targets: ["example-1"]),
        .executable(name: "example-2", targets: ["example-2"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ManuW/Clibpq", from: "0.0.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "postgresql-swift",
            dependencies: []
        ),
        .target(
            name: "example-1",
            dependencies: ["postgresql-swift"]
        ),
        .target(
            name: "example-2",
            dependencies: ["postgresql-swift"]
        ),
        .testTarget(
            name: "postgresql-swiftTests",
            dependencies: ["postgresql-swift"]
        ),
    ]
)

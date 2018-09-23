// swift-tools-version:4.2


import PackageDescription

let package = Package(
    name: "postgresql-swift",
    swiftLanguageVersions: [.v4, .v4_2],
    products: [
        .library(name: "postgresql-swift", targets: ["postgresql-swift"]),
        .executable(name: "example-1", targets: ["example-1"]),
        .executable(name: "example-2", targets: ["example-2"]),
    ],
    targets: [
        .systemLibrary(
            name: "libpq"
        ),
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

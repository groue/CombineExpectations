// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineExpectations",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "CombineExpectations",
            targets: ["CombineExpectations"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "CombineExpectations",
            dependencies: [],
            linkerSettings: [.linkedFramework("XCTest")]),
        .testTarget(
            name: "CombineExpectationsTests",
            dependencies: ["CombineExpectations"]),
    ]
)

#if swift(>=5.4)
  // XCTest was introduced for watchOS with Swift 5.4, Xcode 12.5, and watchOS 7.4.
  package.platforms! += [
    .watchOS("7.4")
  ]
#endif

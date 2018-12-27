// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FragmentedMP4Parser",
    products: [
      .library(name: "FragmentedMP4Parser", targets: ["FragmentedMP4Parser"]),
    ],
    dependencies: [
      .package(url: "../FragmentedMP4Description", .branch("master"))
    ],
    targets: [
        .target(name: "FragmentedMP4Parser", dependencies: ["FragmentedMP4Description"]),
        .testTarget(name: "FragmentedMP4ParserTests", dependencies: ["FragmentedMP4Parser"])
    ]
)

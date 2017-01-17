import PackageDescription

let package = Package(
    name: "FragmentedMP4Parser",
    dependencies: [
      .Package(url: "/Users/sbader/Code/current/magic_box/Frameworks/FragmentedMP4Description", majorVersion: 0)
    ]
)

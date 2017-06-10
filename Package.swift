import PackageDescription

let package = Package(
    name: "FragmentedMP4Parser",
    dependencies: [
      .Package(url: "https://github.com/sbader/FragmentedMP4Description.git", majorVersion: 0)
    ]
)

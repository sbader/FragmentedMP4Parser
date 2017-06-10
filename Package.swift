import PackageDescription

let package = Package(
    name: "FragmentedMP4Parser",
    dependencies: [
      .Package(url: "git@github.com:sbader/FragmentedMP4Description.git", majorVersion: 0)
    ]
)

# FragmentedMP4Parser

Reads the informational data in a fragmented MPEG-4 (fMP4) file. The information parsed can be used to generate playlists for HTTP Live Streaming (HLS).

This parser is tested with fMP4 files produced from the `mediafilesegmenter` utility included with Apple’s HTTP Live Streaming Tools.

## Installation

To install the package add the following line to the `Package.swift` dependencies.

```swift
.Package(url: "https://github.com/sbader/FragmentedMP4Parser.git", majorVersion: 0)
```

## Usage

To use the parser, first import the package:

```swift
import FragmentedMP4Parser
```

Initialize the parser with the path to the file:

```swift
let parser = FragmentedMP4Parser(path: "...Path To The File...")
```

Run the parser with proper error handling:

```swift
do {
    let description = try parser.parse()
}
catch let e {
    print("Parsing the file failed, error thrown \(e)")
}
```

## License

FragmentedMP4Parser is released under the MIT license. See LICENSE for details.

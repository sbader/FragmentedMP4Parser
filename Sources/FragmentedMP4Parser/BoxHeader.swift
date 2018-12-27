import Foundation

struct BoxHeader {
    static let standardHeaderSize = MemoryLayout<UInt32>.size + 4

    let size: Int
    let type: String
    let largeSize: UInt64?
}

extension BoxHeader: CustomStringConvertible {
    var description: String {
        return "BoxHeader(size: \(size), type: '\(type)')"
    }
}

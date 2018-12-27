import Foundation

struct MediaDataBoxInfo {
    static let containerType = "mdat"

    let header: BoxHeader

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()
    }
}

extension MediaDataBoxInfo: CustomStringConvertible {
    var description: String {
        return "MediaDataBoxInfo(header: \(header))"
    }
}

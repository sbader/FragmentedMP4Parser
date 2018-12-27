import Foundation

struct MovieFragmentHeaderBox {
    static let containerType = "mfhd"

    let header: BoxHeader
    let version: UInt8
    let flags: UInt32
    let sequenceNumber: UInt32

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()
        self.version = buffer.readUInt8()
        self.flags = buffer.read24BitMap()
        self.sequenceNumber = buffer.readUInt32BigEndian()
    }
}

extension MovieFragmentHeaderBox: CustomStringConvertible {
    var description: String {
        return "MovieFragmentHeaderBox(header: \(header), version: \(version), flags: \(flags), sequenceNumber: \(sequenceNumber))"
    }
}

import Foundation

struct MovieHeaderBox {
    static let containerType = "mvhd"

    let header: BoxHeader
    let version: UInt8
    let flags: UInt32

    let creationTime: UInt32
    let modificationTime: UInt32
    let timescale: UInt32
    let duration: UInt32

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()
        self.version = buffer.readUInt8()
        self.flags = buffer.read24BitMap()

        if version == 1 {
            fatalError("Not handling version 1 yet")
        }

        self.creationTime = buffer.readUInt32BigEndian()
        self.modificationTime = buffer.readUInt32BigEndian()
        self.timescale = buffer.readUInt32BigEndian()
        self.duration = buffer.readUInt32BigEndian()
    }
}

extension MovieHeaderBox: CustomStringConvertible {
    var description: String {
        return "MovieHeaderBox(header: \(header), version: \(version), flags: \(flags), creationTime: \(creationTime), timescale: \(timescale), duration: \(duration))"
    }
}

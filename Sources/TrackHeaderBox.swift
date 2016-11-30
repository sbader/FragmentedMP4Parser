import Foundation

struct TrackHeaderBox {
    static let containerType = "tkhd"

    let header: BoxHeader

    let version: UInt8
    let flags: UInt32

    let creationTime: UInt32
    let modificationTime: UInt32
    let trackID: UInt32
    let duration: UInt32

    let width: UInt32
    let height: UInt32

    var widthPresentation: Int {
        return Int(width)/65536
    }

    var heightPresentation: Int {
         return Int(height)/65536
    }

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()
        self.version = buffer.readUInt8()
        self.flags = buffer.read24BitMap()
        
        if version == 1 {
            fatalError("Not handling version 1 yet")
        }

        self.creationTime = buffer.readUInt32BigEndian()
        self.modificationTime = buffer.readUInt32BigEndian()
        self.trackID = buffer.readUInt32BigEndian()

        buffer.advance(length: MemoryLayout<UInt32>.size)

        self.duration = buffer.readUInt32BigEndian()

        buffer.advance(length: MemoryLayout<UInt32>.size * 2) // reserved
        buffer.advance(length: MemoryLayout<UInt16>.size) // layer
        buffer.advance(length: MemoryLayout<UInt16>.size) // alternate_group
        buffer.advance(length: MemoryLayout<UInt16>.size) // volume
        buffer.advance(length: MemoryLayout<UInt16>.size) // reserved
        buffer.advance(length: MemoryLayout<UInt32>.size * 9) // unity matrix

        self.width = buffer.readUInt32BigEndian()
        self.height = buffer.readUInt32BigEndian()
    }
}

extension TrackHeaderBox: CustomStringConvertible {
    var description: String {
        return "TrackHeaderBox(header: \(header), version: \(version), flags: \(flags), creationTime: \(creationTime), modificationTime: \(modificationTime), trackID: \(trackID), duration: \(duration), width: \(widthPresentation), height: \(heightPresentation))"
    }
}

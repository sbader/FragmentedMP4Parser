import Foundation

struct MediaHandlerBox {
    static let containerType = "hdlr"

    let header: BoxHeader

    let version: UInt8
    let flags: UInt32
    let type: HandlerType
    let name: String

    enum HandlerType: String {
        case Video = "vide"
        case Audio = "soun"
        case Hint = "hint"
        case Unknown = "unknown"
    }

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()
        self.version = buffer.readUInt8()
        self.flags = buffer.read24BitMap()

        buffer.advance(length: MemoryLayout<UInt32>.size)

        self.type = HandlerType(rawValue: buffer.readASCIIString(length: 4)) ?? HandlerType.Unknown

        buffer.advance(length: MemoryLayout<UInt32>.size * 3)

        let sizeRead = BoxHeader.standardHeaderSize + MemoryLayout<UInt8>.size + MemoryLayout<UInt32>.size + MemoryLayout<UInt32>.size + MemoryLayout<UInt32>.size + (MemoryLayout<UInt32>.size * 3)

        self.name = buffer.readUTF8String(length: buffer.size - sizeRead)
    }
}

extension MediaHandlerBox: CustomStringConvertible {
    var description: String {
        return "MediaHandlerBox(header: \(header), type: \(type), name: \(name))"
    }
}

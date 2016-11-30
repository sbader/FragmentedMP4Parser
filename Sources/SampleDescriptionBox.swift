import Foundation

protocol SampleDescriptionCodecStringConvertible {
    var codecString: String { get }
}

struct SampleDescriptionBox {
    static let containerType = "stsd"

    let header: BoxHeader
    let version: UInt8
    let flags: UInt32

    let handlerType: MediaHandlerBox.HandlerType

    let entryCount: UInt32
    let sampleEntry: SampleDescriptionCodecStringConvertible?

    init(buffer: Buffer, handlerType: MediaHandlerBox.HandlerType) {
        self.header = buffer.readBoxHeader()
        self.handlerType = handlerType
        
        self.version = buffer.readUInt8()
        self.flags = buffer.read24BitMap()
        self.entryCount = buffer.readUInt32BigEndian()

        let sampleBuffer = buffer.readBufferToEnd()

        switch handlerType {
        case .Audio:
            self.sampleEntry = AudioSampleEntry(buffer: sampleBuffer)
        case .Video:
            self.sampleEntry = VisualSampleEntry(buffer: sampleBuffer)
        default:
            self.sampleEntry = nil
        }
    }
}

extension SampleDescriptionBox: CustomStringConvertible {
    var description: String {
        return "SampleDescriptionBox(header: \(header), handlerType: \(handlerType.rawValue), entryCount: \(entryCount), sampleEntry: \(sampleEntry!), codec: \(sampleEntry!.codecString))"
    }
}

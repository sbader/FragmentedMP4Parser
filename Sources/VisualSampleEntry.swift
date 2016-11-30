import Foundation

struct VisualSampleEntry {
    let header: BoxHeader

    var codingName: String { return header.type }

    let avcDecoderConfiguration: AVCDecoderConfigurationRecord

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()

        buffer.advance(length: MemoryLayout<UInt8>.size * 6)
        buffer.advance(length: MemoryLayout<UInt16>.size)

        buffer.advance(length: MemoryLayout<UInt16>.size)
        buffer.advance(length: MemoryLayout<UInt16>.size)
        buffer.advance(length: MemoryLayout<UInt32>.size * 3)
        buffer.advance(length: MemoryLayout<UInt16>.size)
        buffer.advance(length: MemoryLayout<UInt16>.size)

        buffer.advance(length: MemoryLayout<UInt32>.size)
        buffer.advance(length: MemoryLayout<UInt32>.size)
        buffer.advance(length: MemoryLayout<UInt32>.size)
        buffer.advance(length: MemoryLayout<UInt16>.size)
        buffer.advance(length: 32)
        buffer.advance(length: MemoryLayout<UInt16>.size)
        buffer.advance(length: MemoryLayout<Int16>.size)

        self.avcDecoderConfiguration = AVCDecoderConfigurationRecord(buffer: buffer.readBufferToEnd())
    }
}

extension VisualSampleEntry: CustomStringConvertible {
    var description: String {
        return "VisualSampleEntry(header: \(header))"
    }
}

extension VisualSampleEntry: SampleDescriptionCodecStringConvertible {
    var codecString: String {
        return "\(codingName).\(avcDecoderConfiguration.profileString)"
    }
}

import Foundation

struct VisualSampleEntry {
    let header: BoxHeader

    var codingName: String { return header.type }

    let avcDecoderConfiguration: AVCDecoderConfigurationRecord?

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

        var decoderConfiguration: AVCDecoderConfigurationRecord?

        while buffer.hasMoreBytes {
            let nextHeader = buffer.readBoxHeaderAndRewind()

            if (nextHeader.type == "avcC") {
                decoderConfiguration = AVCDecoderConfigurationRecord(buffer: buffer.readBufferToEnd())
            }
            else {
                buffer.advance(length: nextHeader.size)
            }
        }

        self.avcDecoderConfiguration = decoderConfiguration
    }
}

extension VisualSampleEntry: CustomStringConvertible {
    var description: String {
        return "VisualSampleEntry(header: \(header))"
    }
}

extension VisualSampleEntry: SampleDescriptionCodecStringConvertible {
    var codecString: String {
        return "\(codingName).\(avcDecoderConfiguration?.profileString ?? "nil")"
    }
}

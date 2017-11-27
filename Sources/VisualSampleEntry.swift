import Foundation

struct VisualSampleEntry {
    let header: BoxHeader

    var codingName: String { return header.type }

    let avcDecoderConfiguration: AVCDecoderConfigurationRecord?
    let hevcDecoderConfiguration: HEVCDecoderConfigurationRecord?

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

        var avcDecoderConfiguration: AVCDecoderConfigurationRecord?
        var hevcDecoderConfiguration: HEVCDecoderConfigurationRecord?

        while buffer.hasMoreBytes {
            let nextHeader = buffer.readBoxHeaderAndRewind()

            if (nextHeader.type == "avcC") {
                avcDecoderConfiguration = AVCDecoderConfigurationRecord(buffer: buffer.readBufferToEnd())
            }
            else if (nextHeader.type == "hvcC") {
                hevcDecoderConfiguration = HEVCDecoderConfigurationRecord(buffer: buffer.readBufferToEnd())
            }
            else {
                buffer.advance(length: nextHeader.size)
            }
        }

        self.avcDecoderConfiguration = avcDecoderConfiguration
        self.hevcDecoderConfiguration = hevcDecoderConfiguration
    }
}

extension VisualSampleEntry: CustomStringConvertible {
    var description: String {
        return "VisualSampleEntry(header: \(header))"
    }
}

extension VisualSampleEntry: SampleDescriptionCodecStringConvertible {
    var profileString: String {
        if let avcProfileString = avcDecoderConfiguration?.profileString {
            return avcProfileString
        }

        if let hevcProfileString = hevcDecoderConfiguration?.profileString {
            return hevcProfileString
        }

        return "nil"
    }

    var codecString: String {
        return "\(codingName).\(profileString)"
    }
}

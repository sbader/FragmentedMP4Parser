import Foundation

struct MP4Descriptor {
    enum Tag: UInt8 {
        case ESDescriptor = 0x03
        case DecoderConfigurationDescriptor = 0x04
        case DecoderSpecificDescriptor = 0x05
        case SLConfigDescriptor = 0x06
    }

    let tag: Tag
    let size: UInt32
}

struct ESDescriptor {
    let tag = MP4Descriptor.Tag.ESDescriptor
    let size: UInt32
    let esID: UInt16
}

struct DecoderConfigurationDescriptor {
    let tag = MP4Descriptor.Tag.DecoderConfigurationDescriptor
    let size: UInt32
    let objectTypeIndication: UInt8
    let streamType: UInt8
    let bufferSize: UInt32
    let maxBitRate: UInt32
    let averageBitRate: UInt32
}

struct DecoderSpecificDescriptor {
    let tag = MP4Descriptor.Tag.DecoderSpecificDescriptor
    let size: UInt32
    let data: Buffer

    var audioConfigString: String? {
        guard data.size > 0 else { return nil }

        let value = data.readUInt8()
        data.rewind(length: MemoryLayout<UInt8>.size)
        let configValue = (value & 0xF8) >> 3

        return "\(configValue)"
    }
}

struct MP4DescriptorContainer {
    var additionalDescriptors: [MP4Descriptor] = []
    let buffer: Buffer

    var esDescriptor: ESDescriptor? = nil
    var decoderConfigurationDescriptor: DecoderConfigurationDescriptor?
    var decoderSpecificDescriptor: DecoderSpecificDescriptor?

    init(buffer: Buffer) {
        self.buffer = buffer
        parseDescriptor()
    }

    mutating func parseAdditionalDescriptors() {
        while buffer.hasMoreBytes {
            parseDescriptor()
        }
    }

    mutating func parseDescriptor() {
        let tagValue = buffer.readUInt8()

        if buffer.size > 1 {
            let size = buffer.readDescriptorSize()
            let tag = MP4Descriptor.Tag(rawValue: tagValue)

            if tag == .ESDescriptor {
                parseESDescriptor(size: size)
            }
            else if tag == .DecoderConfigurationDescriptor {
                parseDecoderConfigurationDescriptor(size: size)
            }
            else if tag == .DecoderSpecificDescriptor {
                parseDecoderSpecificDescriptor(size: size)
            }
            else {
                parseDefaultDescriptor(tag: tag!, size: size)
            }
        }
    }

    mutating func parseESDescriptor(size: UInt32) {
        let esID = buffer.readUInt16BigEndian()
        let flags = buffer.readUInt8()
        if (flags & 0x80) != 0 {
            buffer.advance(length: MemoryLayout<UInt16>.size)
        }

        if (flags & 0x40) != 0 {
            let stringLength = buffer.readUInt8()
            buffer.advance(length: Int(stringLength))
        }

        if (flags & 0x20) != 0 {
            buffer.advance(length: MemoryLayout<UInt16>.size)
        }

        esDescriptor = ESDescriptor(size: size, esID: esID)

        parseAdditionalDescriptors()
    }

    mutating func parseDecoderConfigurationDescriptor(size: UInt32) {
        let objectTypeIndication = buffer.readUInt8()
        let streamType = buffer.readUInt8()
        let bufferSize = buffer.read24BitMap()
        let maxBitRate = buffer.readUInt32BigEndian()
        let averageBitRate = buffer.readUInt32BigEndian()

        decoderConfigurationDescriptor = DecoderConfigurationDescriptor(size: size,
                                                                        objectTypeIndication: objectTypeIndication,
                                                                        streamType: streamType,
                                                                        bufferSize: bufferSize,
                                                                        maxBitRate: maxBitRate,
                                                                        averageBitRate: averageBitRate)

        parseAdditionalDescriptors()
    }

    mutating func parseDecoderSpecificDescriptor(size: UInt32) {
        decoderSpecificDescriptor = DecoderSpecificDescriptor(size: size,
                                                              data: buffer.readBuffer(length: Int(size)))
    }

    mutating func parseDefaultDescriptor(tag: MP4Descriptor.Tag, size: UInt32) {
        let descriptor = MP4Descriptor(tag: tag, size: size)
        additionalDescriptors.append(descriptor)
        buffer.advance(length: Int(size))
    }

    var codecString: String {
        guard let decoderConfigurationDescriptor = decoderConfigurationDescriptor else  { return "" }

        var fullCodecString = ""
        
        fullCodecString += NSString(format: "%02X", decoderConfigurationDescriptor.objectTypeIndication) as String

        if let audioConfigString = decoderSpecificDescriptor?.audioConfigString {
            fullCodecString += ".\(audioConfigString)"
        }

        return fullCodecString
    }
}

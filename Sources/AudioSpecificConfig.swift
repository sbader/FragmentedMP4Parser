import Foundation

struct AudioSpecificConfig {
    let header: BoxHeader
    let version: UInt8
    let flags: UInt32

    let descriptorContainer: MP4DescriptorContainer

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()
        self.version = buffer.readUInt8()
        self.flags = buffer.read24BitMap()

        self.descriptorContainer = MP4DescriptorContainer(buffer: buffer.readBufferToEnd())
    }

    var objectTypeString: String {
        return descriptorContainer.codecString
    }
}

extension AudioSpecificConfig: CustomStringConvertible {
    var description: String {
        return "AudioSpecificConfig(header: \(header), descriptorContainer: \(descriptorContainer), objectTypeString: \(objectTypeString))"
    }
}

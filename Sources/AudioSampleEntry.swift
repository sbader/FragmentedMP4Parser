import Foundation

struct AudioSampleEntry {
    let header: BoxHeader

    var codingName: String { return header.type }

    let channelCount: UInt16
    let sampleSize: UInt16
    let sampleRate: UInt32

    let audioSpecificConfig: AudioSpecificConfig

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()

        buffer.advance(length: MemoryLayout<UInt8>.size * 6)
        buffer.advance(length: MemoryLayout<UInt16>.size)

        buffer.advance(length: MemoryLayout<UInt32>.size * 2)
        self.channelCount = buffer.readUInt16BigEndian()
        self.sampleSize = buffer.readUInt16BigEndian()

        buffer.advance(length: MemoryLayout<UInt16>.size)
        buffer.advance(length: MemoryLayout<UInt16>.size)

        self.sampleRate = buffer.readUInt32BigEndian()
        self.audioSpecificConfig = AudioSpecificConfig(buffer: buffer.readBufferToEnd())
    }
}

extension AudioSampleEntry: CustomStringConvertible {
    var description: String {
        return "AudioSampleEntry(header: \(header), channelCount: \(channelCount), sampleSize: \(sampleSize), sampleRate: \(sampleRate), audioSpecificConfig: \(audioSpecificConfig))"
    }
}

extension AudioSampleEntry: SampleDescriptionCodecStringConvertible {
    var codecString: String {
        var string = "\(codingName)"

        if audioSpecificConfig.objectTypeString.characters.count > 0 {
            string += ".\(audioSpecificConfig.objectTypeString)"
        }

        return string
    }
}

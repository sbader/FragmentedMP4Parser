import Foundation

struct TrackRunBox {
    static let containerType = "trun"

    let header: BoxHeader

    struct Flags: OptionSet {

        let rawValue: Int

        static let dataOffsetPresent                    = Flags(rawValue: 0x000001)
        static let firstSampleFlagsPresent              = Flags(rawValue: 0x000004)
        static let sampleDurationPresent                = Flags(rawValue: 0x000100)
        static let sampleSizePresent                    = Flags(rawValue: 0x000200)
        static let sampleFlagsPresent                   = Flags(rawValue: 0x000400)
        static let sampleCompositionTimeOffsetsPresent  = Flags(rawValue: 0x000800)

    }

    struct SampleInfo {
        let duration: UInt32?
        let size: UInt32?
        let flags: UInt32?
        let compositionTimeOffset: UInt32?

        var isIFrame: Bool {
            guard let flags = flags else { return false }

            return ((flags >> 24) & 0x3) == 2
        }
    }

    let version: UInt8
    let flags: Flags

    let sampleCount: UInt32
    let dataOffset: Int32?
    let firstSampleFlags: UInt32?
    let samplesInfo: [SampleInfo]?

    let sampleDurationPresent: Bool
    let sampleSizePresent: Bool
    let sampleFlagsPresent: Bool
    let sampleCompositionTimeOffsetsPresent: Bool

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()
        self.version = buffer.readUInt8()
        self.flags = TrackRunBox.Flags(rawValue: Int(buffer.read24BitMap()))

        self.sampleCount = buffer.readUInt32BigEndian()

        var dataOffset: Int32? = nil
        var firstSampleFlags: UInt32? = nil
        var samplesInfo: [TrackRunBox.SampleInfo] = []

        self.sampleDurationPresent = flags.contains(.sampleDurationPresent)
        self.sampleSizePresent = flags.contains(.sampleSizePresent)
        self.sampleFlagsPresent = flags.contains(.sampleFlagsPresent)
        self.sampleCompositionTimeOffsetsPresent = flags.contains(.sampleCompositionTimeOffsetsPresent)

        if flags.contains(.dataOffsetPresent) {
            dataOffset = buffer.readInt32BigEndian()
        }

        if flags.contains(.firstSampleFlagsPresent) {
            firstSampleFlags = buffer.readUInt32BigEndian()
        }

        for _ in 0..<sampleCount {
            var duration: UInt32? = nil
            var sampleSize: UInt32? = nil
            var flags: UInt32? = nil
            var compositionTimeOffset: UInt32? = nil

            if sampleDurationPresent {
                duration = buffer.readUInt32BigEndian()
            }

            if sampleSizePresent {
                sampleSize = buffer.readUInt32BigEndian()
            }

            if sampleFlagsPresent {
                flags = buffer.readUInt32BigEndian()
            }

            if sampleCompositionTimeOffsetsPresent {
                compositionTimeOffset = buffer.readUInt32BigEndian()
            }

            let sampleInfo = TrackRunBox.SampleInfo(duration: duration,
                                                    size: sampleSize,
                                                    flags: flags,
                                                    compositionTimeOffset: compositionTimeOffset)

            samplesInfo.append(sampleInfo)
        }

        self.dataOffset = dataOffset
        self.firstSampleFlags = firstSampleFlags
        self.samplesInfo = samplesInfo
    }
}

extension TrackRunBox: CustomStringConvertible {
    var description: String {
        return "TrackRunBox(header: \(header), flags: \(flags), sampleCount: \(sampleCount), dataOffset: \(dataOffset ?? 0), firstSampleFlags: \(firstSampleFlags ?? 0), sampleDurationPresent: \(sampleDurationPresent), sampleSizePresent: \(sampleSizePresent), sampleFlagsPresent: \(sampleFlagsPresent), sampleCompositionTimeOffsetsPresent: \(sampleCompositionTimeOffsetsPresent))"
    }
}

extension TrackRunBox.SampleInfo: CustomStringConvertible {
    var description: String {
        return "SampleInfo(duration: \(duration ?? 0), size: \(size ?? 0), flags: \(flags ?? 0), compositionTimeOffset: \(compositionTimeOffset ?? 0))"
    }
}

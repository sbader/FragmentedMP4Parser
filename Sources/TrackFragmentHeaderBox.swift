import Foundation

struct TrackFragmentHeaderBox {
    static let containerType = "tfhd"

    let header: BoxHeader

    struct Flags: OptionSet {
        let rawValue: Int

        static let baseDataOffsetPresent            = Flags(rawValue: 0x000001)
        static let sampleDescriptionIndexPresent    = Flags(rawValue: 0x000002)
        static let defaultSampleDurationPresent     = Flags(rawValue: 0x000008)
        static let defaultSampleSizePresent         = Flags(rawValue: 0x000010)
        static let defaultSampleFlagsPresent        = Flags(rawValue: 0x000020)
        static let durationIsEmpty                  = Flags(rawValue: 0x010000)
    }

    let version: UInt8
    let flags: Flags

    let trackID: UInt32
    let baseDataOffset: UInt64?
    let sampleDescriptionIndex: UInt32?
    let defaultSampleDuration: UInt32?
    let defaultSampleSize: UInt32?
    let defaultSampleFlags: UInt32?
    let durationIsEmpty: Bool

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()

        self.version = buffer.readUInt8()
        self.flags = TrackFragmentHeaderBox.Flags(rawValue: Int(buffer.read24BitMap()))
        self.trackID = buffer.readUInt32BigEndian()

        var baseDataOffset: UInt64? = nil
        var sampleDescriptionIndex: UInt32? = nil
        var defaultSampleDuration: UInt32? = nil
        var defaultSampleSize: UInt32? = nil
        var defaultSampleFlags: UInt32? = nil
        var durationIsEmpty = false

        if flags.contains(.baseDataOffsetPresent) {
            baseDataOffset = buffer.readUInt64BigEndian()
        }

        if flags.contains(.sampleDescriptionIndexPresent) {
            sampleDescriptionIndex = buffer.readUInt32BigEndian()
        }

        if flags.contains(.defaultSampleDurationPresent) {
            defaultSampleDuration = buffer.readUInt32BigEndian()
        }

        if flags.contains(.defaultSampleSizePresent) {
            defaultSampleSize = buffer.readUInt32BigEndian()
        }

        if flags.contains(.defaultSampleFlagsPresent) {
            defaultSampleFlags = buffer.readUInt32BigEndian()
        }

        if flags.contains(.durationIsEmpty) {
            durationIsEmpty = true
        }

        self.baseDataOffset = baseDataOffset
        self.sampleDescriptionIndex = sampleDescriptionIndex
        self.defaultSampleDuration = defaultSampleDuration
        self.defaultSampleSize = defaultSampleSize
        self.defaultSampleFlags = defaultSampleFlags
        self.durationIsEmpty = durationIsEmpty
    }
}

extension TrackFragmentHeaderBox: CustomStringConvertible {
    var description: String {
        return "TrackFragmentHeaderBox(header: \(header), version: \(version), flags: \(flags), trackID: \(trackID), baseDataOffset: \(baseDataOffset ?? 0), sampleDescriptionIndex: \(sampleDescriptionIndex ?? 0), defaultSampleDuration: \(defaultSampleDuration ?? 0), defaultSampleSize: \(defaultSampleSize ?? 0), defaultSampleFlags: \(defaultSampleFlags ?? 0), durationIsEmpty: \(durationIsEmpty))"
    }
}

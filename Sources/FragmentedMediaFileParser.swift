import FragmentedMP4Description
import Foundation

/// Parses a fragmented MPEG-4 file into a FragmentedMP4Description container
public class FragmentedMP4Parser {
    static let significantContainers = [
        FileTypeBox.containerType,
        MovieBox.containerType,
        MovieFragmentBox.containerType
    ]

    private let path: String
    private var bytesRead: Int = 0
    private var mediaFileResult: MediaFileBox!

    enum Errors: Error {
        case parsingError
        case fileNotFragmented
        case nonexistentFile
    }

    lazy var fileSize: Int = {
        if let attributes = try? FileManager.default.attributesOfItem(atPath: self.path),
            let fileSizeAttribute = attributes[FileAttributeKey.size] as? Int {
            return fileSizeAttribute
        }

        return 0
    }()

    public init(path: String) {
        self.path = path
    }

    func parseContainer(withFileHandle fileHandle: FileHandle) {
        let sizeData = fileHandle.readData(ofLength: MemoryLayout<UInt32>.size)
        let sizeBuffer = Buffer(data: sizeData)

        let typeData = fileHandle.readData(ofLength: 4)
        let typeBuffer = Buffer(data: typeData)

        let size = sizeBuffer.readUInt32BigEndian()
        let type = typeBuffer.readASCIIString(length: 4)

        let realSize: UInt64

        var boxSize = BoxHeader.standardHeaderSize
        var largeSizeData: Data? = nil

        if size == 1 {
            largeSizeData = fileHandle.readData(ofLength: MemoryLayout<UInt64>.size)
            realSize = Buffer(data: largeSizeData!).readUInt64BigEndian()
            boxSize += MemoryLayout<UInt64>.size
        }
        else {
            realSize = UInt64(size)
        }

        let remainingSize = Int(realSize) - boxSize

        if FragmentedMP4Parser.significantContainers.contains(type) {
            let remainingData = fileHandle.readData(ofLength: remainingSize)

            var joinedData = Data()
            joinedData.append(sizeData)
            joinedData.append(typeData)

            if let largeSizeData = largeSizeData {
                joinedData.append(largeSizeData)
            }

            joinedData.append(remainingData)

            let buffer = Buffer(data: joinedData)

            if type == FileTypeBox.containerType {
                self.mediaFileResult.fileTypeBox = FileTypeBox(buffer: buffer)
            }
            else if type == MovieBox.containerType {
                self.mediaFileResult.movieBox = MovieBox(buffer: buffer)
            }
            else if type == MovieFragmentBox.containerType {
                self.mediaFileResult.movieFragmentBoxes.append(MovieFragmentBox(buffer: buffer))
            }
        }
        else if type == MediaDataBoxInfo.containerType {
            var joinedData = Data()
            joinedData.append(sizeData)
            joinedData.append(typeData)

            if let largeSizeData = largeSizeData {
                joinedData.append(largeSizeData)
            }

            let buffer = Buffer(data: joinedData)
            self.mediaFileResult.mediaDataBoxesInfo.append(MediaDataBoxInfo(buffer: buffer))
            fileHandle.seek(toFileOffset: fileHandle.offsetInFile + UInt64(remainingSize))
        }
        else {
            fileHandle.seek(toFileOffset: fileHandle.offsetInFile + UInt64(remainingSize))
        }

        bytesRead += Int(realSize)
    }

    func iFrameSamples(for mediaFile: MediaFileBox) throws -> [IFrameSample] {
        guard let movieBox = mediaFile.movieBox else {
            throw(Errors.parsingError)
        }

        guard let videoTrack = mediaFile.videoTrack else {
            throw(Errors.parsingError)
        }

        let trackBoxes = movieBox.trackBoxes
        let tracks = trackBoxes.map { (trackBox) -> FragmentedMP4Description.Track in
            let mediaHeaderBox = trackBox.mediaBox.mediaHeaderBox

            return FragmentedMP4Description.Track(trackID: UInt(trackBox.trackHeaderBox.trackID),
                                             timescale: UInt(mediaHeaderBox.timescale),
                                             duration: UInt(mediaHeaderBox.duration),
                                             containsEditLists: false)
        }

        var tracksByID: [UInt:FragmentedMP4Description.Track] = [:]

        for track in tracks {
            tracksByID[track.trackID] = track
        }

        guard let fileTypeBox = mediaFile.fileTypeBox else {
            throw(Errors.parsingError)
        }

        var previousOffset = UInt(fileTypeBox.header.size + movieBox.header.size)

        var timeOffset: UInt = 0

        var iFrameSamples: [IFrameSample] = []
        var currentIFrameSample: IFrameSample? = nil

        for (i, fragmentBox) in mediaFile.movieFragmentBoxes.enumerated() {
            let mediaDataInfo = mediaFile.mediaDataBoxesInfo[i]

            guard let trackFragmentBox = fragmentBox.trackFragmentBox(withID: videoTrack.trackHeaderBox.trackID) else {
                throw(Errors.parsingError)
            }

            guard let track = tracksByID[UInt(trackFragmentBox.trackFragmentHeaderBox.trackID)] else {
                throw(Errors.parsingError)
            }

            let timescale = track.timescale

            let trackFragmentHeaderBox = trackFragmentBox.trackFragmentHeaderBox
            let defaultSampleDuration = trackFragmentHeaderBox.defaultSampleDuration
            let defaultSampleSize = trackFragmentHeaderBox.defaultSampleSize

            var sampleCount = 0

            for trackRunBox in trackFragmentBox.trackRunBoxes {
                sampleCount += Int(trackRunBox.sampleCount)

                var duration: UInt32 = 0

                guard let samplesInfo = trackRunBox.samplesInfo else {
                    throw(Errors.parsingError)
                }

                for (i, sample) in samplesInfo.enumerated() {
                    let size: UInt
                    if trackRunBox.sampleSizePresent {
                        guard let sampleSize = sample.size else {
                            throw(Errors.parsingError)
                        }

                        size = UInt(sampleSize)
                    }
                    else {
                        guard let sampleSize = defaultSampleSize else {
                            throw(Errors.parsingError)
                        }

                        size = UInt(sampleSize)
                    }

                    var sampleIsIFrame: Bool = false

                    if trackRunBox.sampleFlagsPresent {
                        sampleIsIFrame = sample.isIFrame

                        if i == 0 && sample.flags == 0 {
                            sampleIsIFrame = true
                        }
                    }

                    if i == 0 && trackRunBox.firstSampleFlags != nil {
                        guard let firstSampleFlags = trackRunBox.firstSampleFlags else {
                            throw(Errors.parsingError)
                        }

                        sampleIsIFrame = (firstSampleFlags >> 24) & 0x3 == 2
                    }

                    if sampleIsIFrame {
                        if var currentSample = currentIFrameSample {
                            currentSample.presentationDifference = timeOffset - currentSample.timeOffset
                            iFrameSamples.append(currentSample)
                        }

                        let dataOffset = trackRunBox.dataOffset ?? 0

                        currentIFrameSample = IFrameSample(sample: sample,
                                                           byteRangeSize: UInt(size) + UInt(dataOffset),
                                                           byteRangeOffset: UInt(previousOffset),
                                                           timescale: timescale,
                                                           timeOffset: timeOffset,
                                                           presentationDifference: nil)
                    }

                    if trackRunBox.sampleDurationPresent {
                        guard let sampleDuration = sample.duration else {
                            throw(Errors.parsingError)
                        }

                        duration += sampleDuration
                        timeOffset += UInt(sampleDuration)
                    }
                    else {
                        guard let sampleDuration = defaultSampleDuration else {
                            throw(Errors.parsingError)
                        }

                        duration += sampleDuration
                        timeOffset += UInt(sampleDuration)
                    }
                }
            }

            let byteRangeSize = UInt(mediaDataInfo.header.size + fragmentBox.header.size)
            let byteRangeOffset = UInt(previousOffset)

            previousOffset = UInt(byteRangeSize + byteRangeOffset)
        }

        if var sample = currentIFrameSample {
            sample.presentationDifference = timeOffset - sample.timeOffset
            iFrameSamples.append(sample)
        }

        return iFrameSamples
    }

    func fragments(for mediaFile: MediaFileBox) throws -> [FragmentedMP4Description.Fragment] {
        let fileURI = NSString(string: path).lastPathComponent

        guard let movieBox = mediaFile.movieBox else {
            throw(Errors.parsingError)
        }

        guard let videoTrack = mediaFile.videoTrack else {
            throw(Errors.parsingError)
        }

        let trackBoxes = movieBox.trackBoxes
        let tracks = trackBoxes.map { (trackBox) -> FragmentedMP4Description.Track in
            let mediaHeaderBox = trackBox.mediaBox.mediaHeaderBox

            return FragmentedMP4Description.Track(trackID: UInt(trackBox.trackHeaderBox.trackID),
                                             timescale: UInt(mediaHeaderBox.timescale),
                                             duration: UInt(mediaHeaderBox.duration),
                                             containsEditLists: false)
        }

        var tracksByID: [UInt:FragmentedMP4Description.Track] = [:]

        for track in tracks {
            tracksByID[track.trackID] = track
        }

        guard let fileTypeBox = mediaFile.fileTypeBox else {
            throw(Errors.parsingError)
        }

        var previousOffset = UInt(fileTypeBox.header.size + movieBox.header.size)

        var fragments: [FragmentedMP4Description.Fragment] = []

        var timeOffset: UInt = 0

        var peakFrameRate: Double = 0.0

        for (i, fragmentBox) in mediaFile.movieFragmentBoxes.enumerated() {
            let mediaDataInfo = mediaFile.mediaDataBoxesInfo[i]

            guard let trackFragmentBox = fragmentBox.trackFragmentBox(withID: videoTrack.trackHeaderBox.trackID) else {
                throw(Errors.parsingError)
            }

            guard let track = tracksByID[UInt(trackFragmentBox.trackFragmentHeaderBox.trackID)] else {
                throw(Errors.parsingError)
            }

            let timescale = track.timescale

            let trackFragmentHeaderBox = trackFragmentBox.trackFragmentHeaderBox
            let defaultSampleDuration = trackFragmentHeaderBox.defaultSampleDuration

            var trackFragmentBoxDuration: UInt32 = 0

            var sampleCount = 0

            for trackRunBox in trackFragmentBox.trackRunBoxes {
                sampleCount += Int(trackRunBox.sampleCount)

                let trackRunboxDuration: UInt32

                if trackRunBox.sampleDurationPresent {
                    var duration: UInt32 = 0

                    guard let samplesInfo = trackRunBox.samplesInfo else {
                        throw(Errors.parsingError)
                    }

                    for sample in samplesInfo {
                        guard let sampleDuration = sample.duration else {
                            throw(Errors.parsingError)
                        }

                        duration += sampleDuration
                        timeOffset += UInt(sampleDuration)
                    }

                    trackRunboxDuration = duration
                }
                else {
                    guard let sampleDuration = defaultSampleDuration else {
                        throw(Errors.parsingError)
                    }

                    trackRunboxDuration = sampleDuration * trackRunBox.sampleCount
                    timeOffset += UInt(sampleDuration * trackRunBox.sampleCount)
                }

                let frameRate = Double(trackRunBox.sampleCount) / (Double(trackRunboxDuration)/Double(timescale))

                if frameRate > peakFrameRate {
                    peakFrameRate = frameRate
                }


                trackFragmentBoxDuration += trackRunboxDuration
            }

            let fragment = FragmentedMP4Description.Fragment(sequenceNumber: UInt(fragmentBox.movieFragmentHeaderBox.sequenceNumber),
                                                        duration: UInt(trackFragmentBoxDuration),
                                                        timescale: UInt(timescale),
                                                        byteRangeSize: UInt(mediaDataInfo.header.size + fragmentBox.header.size),
                                                        byteRangeOffset: UInt(previousOffset),
                                                        URI: fileURI)

            previousOffset = UInt(fragment.byteRangeSize + fragment.byteRangeOffset)

            fragments.append(fragment)
        }


        return fragments
    }

    func peakFrameRate(for mediaFile: MediaFileBox) throws -> Double {
        var peakFrameRate: Double = 0.0

        guard let movieBox = mediaFile.movieBox else {
            throw(Errors.parsingError)
        }

        guard let videoTrack = mediaFile.videoTrack else {
            throw(Errors.parsingError)
        }

        let trackBoxes = movieBox.trackBoxes
        let tracks = trackBoxes.map { (trackBox) -> FragmentedMP4Description.Track in
            let mediaHeaderBox = trackBox.mediaBox.mediaHeaderBox

            return FragmentedMP4Description.Track(trackID: UInt(trackBox.trackHeaderBox.trackID),
                                             timescale: UInt(mediaHeaderBox.timescale),
                                             duration: UInt(mediaHeaderBox.duration),
                                             containsEditLists: false)
        }

        var tracksByID: [UInt:FragmentedMP4Description.Track] = [:]

        for track in tracks {
            tracksByID[track.trackID] = track
        }

        for fragmentBox in mediaFile.movieFragmentBoxes {
            guard let trackFragmentBox = fragmentBox.trackFragmentBox(withID: videoTrack.trackHeaderBox.trackID) else {
                throw(Errors.parsingError)
            }

            guard let track = tracksByID[UInt(trackFragmentBox.trackFragmentHeaderBox.trackID)] else {
                throw(Errors.parsingError)
            }


            let timescale = track.timescale

            let trackFragmentHeaderBox = trackFragmentBox.trackFragmentHeaderBox
            let defaultSampleDuration = trackFragmentHeaderBox.defaultSampleDuration

            for trackRunBox in trackFragmentBox.trackRunBoxes {
                let trackRunboxDuration: UInt32

                if trackRunBox.sampleDurationPresent {
                    var duration: UInt32 = 0

                    guard let samplesInfo = trackRunBox.samplesInfo else {
                        throw(Errors.parsingError)
                    }

                    for sample in samplesInfo {
                        guard let sampleDuration = sample.duration else {
                            throw(Errors.parsingError)
                        }

                        duration += sampleDuration
                    }

                    trackRunboxDuration = duration
                }
                else {
                    guard let sampleDuration = defaultSampleDuration else {
                        throw(Errors.parsingError)
                    }

                    trackRunboxDuration = sampleDuration * trackRunBox.sampleCount
                }

                let frameRate = Double(trackRunBox.sampleCount) / (Double(trackRunboxDuration)/Double(timescale))

                if frameRate > peakFrameRate {
                    peakFrameRate = frameRate
                }
            }
        }

        return peakFrameRate
    }

    func findAudioCodec(in mediaFile: MediaFileBox) -> String? {

        return nil
    }

    func findVideoCodec(in mediaFile: MediaFileBox) -> String? {

        return nil
    }

    public func parse() throws -> FragmentedMP4Description {
        mediaFileResult = MediaFileBox()

        guard FileManager.default.fileExists(atPath: path) else {
            throw(Errors.nonexistentFile)
        }

        guard let fileHandle = FileHandle(forReadingAtPath: path) else {
            throw(Errors.parsingError)
        }

        while bytesRead < fileSize {
            parseContainer(withFileHandle: fileHandle)
        }

        guard let movieBox = mediaFileResult.movieBox else {
            throw(Errors.parsingError)
        }

        guard let fileTypeBox = mediaFileResult.fileTypeBox else {
            throw(Errors.parsingError)
        }


        let fileURI = NSString(string: path).lastPathComponent

        let initializationInfo = FragmentedMP4Description.InitializationInfo(URI: fileURI,
                                                                        byteRangeSize: UInt(fileTypeBox.header.size + movieBox.header.size),
                                                                        byteRangeOffset: 0)

        guard let videoTrack = mediaFileResult.videoTrack else {
            throw(Errors.parsingError)
        }

        guard let audioTrack = mediaFileResult.audioTrack else {
            throw(Errors.parsingError)
        }


        let videoCodec = videoTrack.mediaBox.mediaInformationBox.sampleTableBox.sampleDescriptionBox.sampleEntry?.codecString ?? ""

        let audioCodec = audioTrack.mediaBox.mediaInformationBox.sampleTableBox.sampleDescriptionBox.sampleEntry?.codecString ?? ""

        let fileInfo = FragmentedMP4Description.FileInfo(majorBrand: fileTypeBox.majorBrand,
                                                         minorVersion: UInt(fileTypeBox.minorVersion),
                                                         compatibleBrands: fileTypeBox.compatibleBrands)

        let trackBoxes = movieBox.trackBoxes
        let tracks = trackBoxes.map { (trackBox) -> FragmentedMP4Description.Track in
            let mediaHeaderBox = trackBox.mediaBox.mediaHeaderBox

            return FragmentedMP4Description.Track(trackID: UInt(trackBox.trackHeaderBox.trackID),
                                             timescale: UInt(mediaHeaderBox.timescale),
                                             duration: UInt(mediaHeaderBox.duration),
                                             containsEditLists: false)
        }

        var tracksByID: [UInt:FragmentedMP4Description.Track] = [:]

        for track in tracks {
            tracksByID[track.trackID] = track
        }

        let resolution = (width: UInt(videoTrack.trackHeaderBox.widthPresentation),
                          height: UInt(videoTrack.trackHeaderBox.heightPresentation))

        let fragments = try self.fragments(for: mediaFileResult)

        guard fragments.count > 0 else {
            throw(Errors.fileNotFragmented)
        }

        let iFrameSamples = try self.iFrameSamples(for: mediaFileResult)

        let iFrames: [FragmentedMP4Description.IFrame] = iFrameSamples.map { (sample) -> FragmentedMP4Description.IFrame in
            return FragmentedMP4Description.IFrame(duration: sample.presentationDifference ?? 0,
                                              timescale: sample.timescale,
                                              byteRangeSize: sample.byteRangeSize,
                                              byteRangeOffset: sample.byteRangeOffset)
        }

        var fragmentTotalSize: Double = 0
        var fragmentTotalDuration: Double = 0
        var fragmentPeakBitRate: Double = 0

        for fragment in fragments {
            fragmentTotalSize += Double(fragment.byteRangeSize)
            fragmentTotalDuration += Double(fragment.durationInSeconds)

            let bitRate = 8.0 * (Double(fragment.byteRangeSize)/Double(fragment.durationInSeconds))
            if bitRate > fragmentPeakBitRate {
                fragmentPeakBitRate = bitRate
            }
        }

        var iFrameTotalSize: Double = 0
        var iFramePeakBitRate: Double = 0

        for iFrame in iFrames {
            iFrameTotalSize += Double(iFrame.byteRangeSize)
            let bitRate = 8.0 * (Double(iFrame.byteRangeSize)/Double(iFrame.durationInSeconds))

            if bitRate > iFramePeakBitRate {
                iFramePeakBitRate = bitRate
            }
        }

        let averageSegmentBitRate = 8.0 * (fragmentTotalSize/fragmentTotalDuration)
        let averageIFrameBitRate = 8.0 * (iFrameTotalSize/fragmentTotalDuration)

        let peakFrameRate = try self.peakFrameRate(for: mediaFileResult)
        let peakFrameRateRounded = Double(round(100_000 * peakFrameRate) / 100_000)

        let mediaInfo = FragmentedMP4Description.MediaInfo(peakBitRate: UInt(fragmentPeakBitRate),
                                                           averageBitRate: UInt(averageSegmentBitRate),
                                                           iFramePeakBitRate: UInt(iFramePeakBitRate),
                                                           iFrameAverageBitRate: UInt(averageIFrameBitRate),
                                                           audioCodec: audioCodec,
                                                           videoCodec: videoCodec,
                                                           resolution: resolution,
                                                           peakFrameRate: peakFrameRateRounded)

        return FragmentedMP4Description(fileInfo: fileInfo,
                                        mediaInfo: mediaInfo,
                                        initializationInfo: initializationInfo,
                                        tracks: tracks,
                                        fragments: fragments,
                                        iFrames: iFrames)
    }
}

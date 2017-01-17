import XCTest

import FragmentedMP4Description

@testable import FragmentedMP4Parser

class FragmentedMP4DescriptionTests: XCTestCase {

    func testSuccessfulParsing() {
        let path = FragmentedMP4DescriptionTests.resourcePath(withFilename: "sample_video_fragmented.mp4")
        let parser = FragmentedMP4Parser(path: path)

        guard let _ = try? parser.parse() else {
            XCTFail("Could not parse media file at \(path)")
            return
        }
    }

    func testFailedParsing() {
        let path = FragmentedMP4DescriptionTests.resourcePath(withFilename: "sample_video_non_fragmented.mp4")
        let parser = FragmentedMP4Parser(path: path)

        XCTAssertThrowsError(try parser.parse()) { (error) in
            switch error {
            case FragmentedMP4Parser.Errors.fileNotFragmented: break
            default:
                XCTFail("Expected to receive fileNotFragmentedError")
            }
        }
    }

    func testDifferentParsing() {
        let path = "/Volumes/Pullo/Sort/Conversion/Sneaky Pete - S01E01 - Pilot-converted.mp4"
        let parser = FragmentedMP4Parser(path: path)

        guard let _ = try? parser.parse() else {
            XCTFail("Could not parse media file at \(path)")
            return
        }
    }

    func testMediaInfo() {
        let mediaInfo = container.mediaInfo
        XCTAssertEqual(mediaInfo.peakBitRate, 701_988)
        XCTAssertEqual(mediaInfo.averageBitRate, 615_381)
        XCTAssertEqual(mediaInfo.iFramePeakBitRate, 177_252)
        XCTAssertEqual(mediaInfo.iFrameAverageBitRate, 31_348)
        XCTAssertEqual(mediaInfo.audioCodec, "mp4a.40.2")
        XCTAssertEqual(mediaInfo.videoCodec, "avc1.4D400D")
        XCTAssertEqual(mediaInfo.resolution.width, 320)
        XCTAssertEqual(mediaInfo.resolution.height, 240)
        XCTAssertEqual(mediaInfo.peakFrameRate, 15.0)
    }

    func testFileInfo() {
        let fileInfo = container.fileInfo
        XCTAssertEqual(fileInfo.majorBrand, "mp42")
        XCTAssertEqual(fileInfo.minorVersion, 1)
        XCTAssertEqual(fileInfo.compatibleBrands, ["mp41", "mp42", "isom", "hlsf"])
    }

    func testInitializationInfo() {
        let initializationInfo = container.initializationInfo
        XCTAssertEqual(initializationInfo.URI, "sample_video_fragmented.mp4")
        XCTAssertEqual(initializationInfo.byteRangeSize, 1124)
        XCTAssertEqual(initializationInfo.byteRangeOffset, 0)
    }

    func testTracks() {
        let tracks = container.tracks
        XCTAssertEqual(tracks.count, 2)

        let videoTrack = tracks[0]
        let audioTrack = tracks[1]
        XCTAssertEqual(videoTrack.trackID, 1)
        XCTAssertEqual(videoTrack.timescale, 15_360)
        XCTAssertEqual(videoTrack.duration, 0)
        XCTAssertEqual(videoTrack.containsEditLists, false)

        XCTAssertEqual(audioTrack.trackID, 2)
        XCTAssertEqual(audioTrack.timescale, 48_000)
        XCTAssertEqual(audioTrack.duration, 0)
        XCTAssertEqual(audioTrack.containsEditLists, false)
    }

    func testFragments() {
        let fragments = container.fragments
        XCTAssertEqual(fragments.count, 3)

        let fragment1 = fragments[0]
        let fragment2 = fragments[1]
        let fragment3 = fragments[2]

        XCTAssertEqual(fragment1.sequenceNumber, 1)
        XCTAssertEqual(fragment1.duration, 129_024)
        XCTAssertEqual(fragment1.timescale, 15_360)
        XCTAssertEqual(fragment1.byteRangeSize, 718_679)
        XCTAssertEqual(fragment1.byteRangeOffset, 1_124)
        XCTAssertEqual(fragment1.URI, "sample_video_fragmented.mp4")

        XCTAssertEqual(fragment2.sequenceNumber, 2)
        XCTAssertEqual(fragment2.duration, 70_656)
        XCTAssertEqual(fragment2.timescale, 15_360)
        XCTAssertEqual(fragment2.byteRangeSize, 274_099)
        XCTAssertEqual(fragment2.byteRangeOffset, 719_803)
        XCTAssertEqual(fragment2.URI, "sample_video_fragmented.mp4")

        XCTAssertEqual(fragment3.sequenceNumber, 3)
        XCTAssertEqual(fragment3.duration, 10_240)
        XCTAssertEqual(fragment3.timescale, 15_360)
        XCTAssertEqual(fragment3.byteRangeSize, 58_499)
        XCTAssertEqual(fragment3.byteRangeOffset, 993_902)
        XCTAssertEqual(fragment3.URI, "sample_video_fragmented.mp4")
    }

    func testIFrames() {
        let iFrames = container.iFrames
        XCTAssertEqual(iFrames.count, 3)

        let iFrame1 = iFrames[0]
        let iFrame2 = iFrames[1]
        let iFrame3 = iFrames[2]

        XCTAssertEqual(iFrame1.duration, 129_024)
        XCTAssertEqual(iFrame1.timescale, 15_360)
        XCTAssertEqual(iFrame1.byteRangeSize, 26_056)
        XCTAssertEqual(iFrame1.byteRangeOffset, 1_124)

        XCTAssertEqual(iFrame2.duration, 70_656)
        XCTAssertEqual(iFrame2.timescale, 15_360)
        XCTAssertEqual(iFrame2.byteRangeSize, 12_727)
        XCTAssertEqual(iFrame2.byteRangeOffset, 719_803)

        XCTAssertEqual(iFrame3.duration, 10_240)
        XCTAssertEqual(iFrame3.timescale, 15_360)
        XCTAssertEqual(iFrame3.byteRangeSize, 14_771)
        XCTAssertEqual(iFrame3.byteRangeOffset, 993_902)
    }

    lazy var container: FragmentedMP4Description = {
        let path = FragmentedMP4DescriptionTests.resourcePath(withFilename: "sample_video_fragmented.mp4")
        let parser = FragmentedMP4Parser(path: path)

        return try! parser.parse()
    }()

    static func resourcePath(withFilename filename: String) -> String {
        return URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent(filename)
            .path
    }

}

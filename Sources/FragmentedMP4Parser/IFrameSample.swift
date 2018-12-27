import Foundation

public struct IFrameSample {
    let sample: TrackRunBox.SampleInfo
    let byteRangeSize: UInt
    let byteRangeOffset: UInt
    let timescale: UInt
    let timeOffset: UInt
    var presentationDifference: UInt? = nil

    var timeOffsetInSeconds: Double {
        return Double(timeOffset)/Double(timescale)
    }

    var presentationDifferenceInSeconds: Double {
        guard let presentationDifference = presentationDifference else { return 0.0 }

        return Double(presentationDifference)/Double(timescale)
    }

    var byteRange: String {
        return "\(byteRangeSize)@\(byteRangeOffset)"
    }
}

extension IFrameSample: CustomStringConvertible {
    public var description: String {
        return "IFrameSample(byteRange: \(byteRange), timeOffsetInSeconds: \(timeOffsetInSeconds), duration: \(sample.duration ?? 0), presentationDifferenceInSeconds: \(presentationDifferenceInSeconds))"
    }
}

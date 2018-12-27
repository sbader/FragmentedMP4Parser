import Foundation

struct FragmentInfo {
    let duration: UInt32
    let timescale: UInt32
    let byteRangeSize: UInt32
    let byteRangeOffset: UInt32
    let URI: String

    var seconds: Float {
        return Float(duration)/Float(timescale)
    }
}

extension FragmentInfo: CustomStringConvertible {
    var description: String {
        return "FragmentInfo(seconds: \(seconds), duration: \(duration), timescale: \(timescale), byteRangeSize: \(byteRangeSize), byteRangeOffset: \(byteRangeOffset), URI: '\(URI)')"
    }
}

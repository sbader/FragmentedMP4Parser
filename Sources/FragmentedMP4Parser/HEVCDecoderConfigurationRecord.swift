import Foundation

extension Data {
    private static let hexAlphabet = "0123456789abcdef".unicodeScalars.map { $0 }

    public func hexEncodedString() -> String {
        return String(self.reduce(into: "".unicodeScalars, { (result, value) in
            result.append(Data.hexAlphabet[Int(value/16)])
            result.append(Data.hexAlphabet[Int(value%16)])
        }))
    }
}

extension UInt32 {
    var reversedBits: UInt32 {
        var n: UInt32 = self
        var m: UInt32 = 0
        var i: UInt32 = 32

        while i > 0 && n != 0  {
            m = m << 1 + n & 0b1
            n = n >> 1
            i -= 1
        }

        m = m << i

        return m
    }
}

struct HEVCDecoderConfigurationRecord {
    let header: BoxHeader

    let stringValue: String

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()

        var fields: [String] = []

//        let version = buffer.readUInt8()
        buffer.advance(length: 1)
        let profile_indication = buffer.readUInt8()
        let general_profile_compatibility_flags = buffer.readUInt32BigEndian()

        var general_constraint_indicator_flags: [UInt8] = []

        for _ in 1...6 {
            general_constraint_indicator_flags.append(buffer.readUInt8())
        }

        let general_level_idc = buffer.readUInt8()

        buffer.advance(length: 8)

        buffer.advance(length: 2)
//        let length_size_minus_one = buffer.readUInt8()
//        let num_of_arrays = buffer.readUInt8()

        let general_profile_space = profile_indication >> 6
        let general_tier_flag = ((profile_indication >> 5) & 1) == 1
        let general_profile_idc = profile_indication & 0x1f;

        let general_profile_spaceString: String

        switch (general_profile_space) {
        case 0:
            general_profile_spaceString = ""
        case 1:
            general_profile_spaceString = "A"
        case 2:
            general_profile_spaceString = "B";
        case 3:
            general_profile_spaceString = "C"
        default:
            general_profile_spaceString = ""
        }

        fields.append(general_profile_spaceString + String(general_profile_idc))

        let general_profile_compatibility_flagsValue = general_profile_compatibility_flags.reversedBits

//        var general_profile_compatibility_flagsValue = general_profile_compatibility_flags
//        general_profile_compatibility_flagsValue = ((general_profile_compatibility_flagsValue & 0x55555555) << 1) | ((general_profile_compatibility_flagsValue & 0xAAAAAAAA) >> 1)
//        general_profile_compatibility_flagsValue = ((general_profile_compatibility_flagsValue & 0x33333333) << 2) | ((general_profile_compatibility_flagsValue & 0xCCCCCCCC) >> 2)
//        general_profile_compatibility_flagsValue = ((general_profile_compatibility_flagsValue & 0x0F0F0F0F) << 4) | ((general_profile_compatibility_flagsValue & 0xF0F0F0F0) >> 4)
//
        let bytes: [UInt8] = [
            UInt8(general_profile_compatibility_flagsValue & 0xFF),
            UInt8((general_profile_compatibility_flagsValue >> 8) & 0xFF),
            UInt8((general_profile_compatibility_flagsValue >> 16) & 0xFF),
            UInt8((general_profile_compatibility_flagsValue >> 24) & 0xFF)
        ]

        let bytesData = Data(bytes: bytes)
        var hexString = bytesData.hexEncodedString()

        while hexString.hasPrefix("0") {
            hexString = String(hexString.dropFirst())
        }

        fields.append(hexString)
        fields.append((general_tier_flag ? "H" : "L") + String(general_level_idc))

        var constraints = general_constraint_indicator_flags
        var removeSize = 0
        for constraint in constraints.reversed() {
            if constraint == 0 {
                removeSize += 1
            }
            else {
                break
            }
        }

        constraints = Array(constraints.dropLast(removeSize))

        let constraintsBytesData = Data(bytes: constraints)

        var constraintsHexString = constraintsBytesData.hexEncodedString()

        while constraintsHexString.hasPrefix("0") {
            constraintsHexString = String(constraintsHexString.dropFirst())
        }

        fields.append(constraintsHexString)

        self.stringValue = fields.joined(separator: ".")
    }


    
    var profileString: String {
        return self.stringValue
    }
}

extension HEVCDecoderConfigurationRecord: CustomStringConvertible {
    var description: String {
        return "HEVCDecoderConfigurationRecord(header: \(header))"
    }
}

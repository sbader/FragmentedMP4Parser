import Foundation

struct AVCDecoderConfigurationRecord {
    let header: BoxHeader

    let configurationVersion: UInt8
    let profileIndication: UInt8
    let profileCompatibility: UInt8
    let levelIndication: UInt8

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()
        self.configurationVersion = buffer.readUInt8()
        self.profileIndication = buffer.readUInt8()
        self.profileCompatibility = buffer.readUInt8()
        self.levelIndication = buffer.readUInt8()
    }

    var profileString: String {
        return NSString(format: "%02X%02X%02X", profileIndication, profileCompatibility, levelIndication) as String
    }
}

extension AVCDecoderConfigurationRecord: CustomStringConvertible {
    var description: String {
        return "AVCDecoderConfigurationRecord(header: \(header), configurationVersion: \(configurationVersion), profileIndication: \(profileIndication), profileCompatibility: \(profileCompatibility), levelIndication: \(levelIndication))"
    }
}

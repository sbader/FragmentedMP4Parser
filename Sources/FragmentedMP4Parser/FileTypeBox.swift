import Foundation

struct FileTypeBox {
    static let containerType = "ftyp"

    let header: BoxHeader
    let majorBrand: String
    let minorVersion: UInt32
    let compatibleBrands: [String]

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()
        self.majorBrand = buffer.readASCIIString(length: 4)
        self.minorVersion = buffer.readUInt32BigEndian()

        var brands = [String]()
        while buffer.hasMoreBytes {
            brands.append(buffer.readASCIIString(length: 4))
        }

        self.compatibleBrands = brands
    }
}

extension FileTypeBox: CustomStringConvertible {
    var description: String {
        return "FileTypeBox(header: \(header), majorBrand: \(majorBrand), minorVersion: \(minorVersion), compatibleBrands: \(compatibleBrands))"
    }
}

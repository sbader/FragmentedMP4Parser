import Foundation

extension Buffer {
    func readUInt8() -> UInt8 {
        return read(length: 1).first!
    }

    func readUInt16LittleEndian() -> UInt16 {
        let buffer = read(length: MemoryLayout<UInt16>.size)

        var int: UInt16 = 0
        for (i, v) in buffer.enumerated() {
            int |= UInt16(v) << UInt16(i * 8)
        }

        return int
    }

    func readUInt16BigEndian() -> UInt16 {
        return readUInt16LittleEndian().bigEndian
    }

    func readUInt32LittleEndian() -> UInt32 {
        let buffer = read(length: MemoryLayout<UInt32>.size)

        var int: UInt32 = 0
        for (i, v) in buffer.enumerated() {
            int |= UInt32(v) << UInt32(i * 8)
        }

        return int
    }

    func readUInt32BigEndian() -> UInt32 {
        return readUInt32LittleEndian().bigEndian
    }

    func readUInt64LittleEndian() -> UInt64 {
        let buffer = read(length: MemoryLayout<UInt64>.size)

        var int: UInt64 = 0
        for (i, v) in buffer.enumerated() {
            int |= UInt64(v) << UInt64(i * 8)
        }

        return int
    }

    func readUInt64BigEndian() -> UInt64 {
        return readUInt64LittleEndian().bigEndian
    }

    func readInt32LittleEndian() -> Int32 {
        let buffer = read(length: MemoryLayout<Int32>.size)

        var int: Int32 = 0
        for (i, v) in buffer.enumerated() {
            int |= Int32(v) << Int32(i * 8)
        }

        return int
    }

    func readInt32BigEndian() -> Int32 {
        return readInt32LittleEndian().bigEndian
    }

    func readASCIIString(length: Int) -> String {
        let buffer = read(length: length)

        return String(bytes: buffer, encoding: String.Encoding.ascii)!
    }

    func readUTF8String(length: Int) -> String {
        let buffer = read(length: length)

        return String(bytes: buffer, encoding: String.Encoding.utf8)!
    }

    func read24BitMap() -> UInt32 {
        let bit1 = readUInt8()
        let bit2 = readUInt8()
        let bit3 = readUInt8()

        var int: UInt32 = UInt32(bit3)

        int += UInt32(bit2) << 8
        int += UInt32(bit1) << 16

        return int
    }

    func readBoxHeader() -> BoxHeader {
        let size = readUInt32BigEndian()
        let type = readASCIIString(length: 4)
        var largeSize: UInt64? = nil

        if size == 1 {
            largeSize = readUInt64BigEndian()
        }

        return BoxHeader(size: Int(size), type: type, largeSize: largeSize)
    }

    func readBoxHeaderAndRewind() -> BoxHeader {
        let size = readUInt32BigEndian()
        let type = readASCIIString(length: 4)
        var largeSize: UInt64? = nil
        var rewindLength = BoxHeader.standardHeaderSize

        if size == 1 {
            largeSize = readUInt64BigEndian()
            rewindLength = MemoryLayout<UInt64>.size
        }
        
        rewind(length: rewindLength)
        
        return BoxHeader(size: Int(size), type: type, largeSize: largeSize)
    }
}

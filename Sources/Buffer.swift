import Foundation

class Buffer {
    private let storage: [UInt8]
    internal private(set) var position: Int = 0

    var size: Int {
        return storage.count
    }

    var remainingBytes: Int {
        return size - position
    }

    init(storage: [UInt8]) {
        self.storage = storage
    }

    init(data: Data) {
        var buffer = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &buffer, count: data.count)

        self.storage = buffer
    }

    func readDescriptorSize() -> UInt32 {
        var size = 0
        var headerSize = 0
        var byteRead = readUInt8()

        headerSize += 2
        var times = 0
        while (byteRead & 0x80) != 0 {
            size = Int(byteRead & 0x7F) << Int(7)
            byteRead = readUInt8()
            headerSize += 1
            times += 1
        }

        size += Int(byteRead) & 0x7F

        return UInt32(size)
    }

    func read(length: Int) -> [UInt8] {
        let value = storage[position..<(position + length)]
        position += length

        return Array(value)
    }

    func readBufferToEnd() -> Buffer {
        return Buffer(storage: read(length: size - position))
    }

    func readBuffer(length: Int) -> Buffer {
        return Buffer(storage: read(length: length))
    }

    func advance(length: Int) {
        position = position + length
    }

    func rewind(length: Int) {
        position = position - length
    }

    var hasMoreBytes: Bool {
        return position < (size - 1)
    }
}

import Foundation

struct MediaBox {
    static let containerType = "mdia"

    static let significantContainers = [
        MediaHeaderBox.containerType,
        MediaHandlerBox.containerType,
        MediaInformationBox.containerType
    ]

    let header: BoxHeader
    let mediaHeaderBox: MediaHeaderBox
    let handlerBox: MediaHandlerBox
    let mediaInformationBox: MediaInformationBox

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()

        var mediaHeaderBox: MediaHeaderBox?
        var mediaHandlerBox: MediaHandlerBox?
        var mediaInformationBuffer: Buffer?

        while buffer.hasMoreBytes {
            let nextHeader = buffer.readBoxHeaderAndRewind()

            if MediaBox.significantContainers.contains(nextHeader.type) {
                let nextBuffer = buffer.readBuffer(length: nextHeader.size)

                if nextHeader.type == MediaHeaderBox.containerType {
                    mediaHeaderBox = MediaHeaderBox(buffer: nextBuffer)
                }
                else if nextHeader.type == MediaHandlerBox.containerType {
                    mediaHandlerBox = MediaHandlerBox(buffer: nextBuffer)
                }
                else if nextHeader.type == MediaInformationBox.containerType {
                    mediaInformationBuffer = nextBuffer
                }
            }
            else {
                buffer.advance(length: nextHeader.size)
            }
        }

        self.mediaHeaderBox = mediaHeaderBox!
        self.handlerBox = mediaHandlerBox!

        self.mediaInformationBox = MediaInformationBox(buffer: mediaInformationBuffer!,
                                                       handlerType: self.handlerBox.type)
    }
}

extension MediaBox: CustomStringConvertible {
    var description: String {
        return "MediaBox(header: \(header), mediaHeaderBox: \(mediaHeaderBox), handlerBox: \(handlerBox), mediaInformationBox: \(mediaInformationBox))"
    }
}

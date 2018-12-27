import Foundation

struct SampleTableBox {
    static let containerType = "stbl"

    static let significantContainers = [
        SampleDescriptionBox.containerType
    ]

    let header: BoxHeader
    let sampleDescriptionBox: SampleDescriptionBox
    let handlerType: MediaHandlerBox.HandlerType

    init(buffer: Buffer, handlerType: MediaHandlerBox.HandlerType) {
        self.header = buffer.readBoxHeader()
        self.handlerType = handlerType

        var sampleDescriptionBox: SampleDescriptionBox?

        while buffer.hasMoreBytes {
            let nextHeader = buffer.readBoxHeaderAndRewind()

            if SampleTableBox.significantContainers.contains(nextHeader.type) {
                let nextBuffer = buffer.readBuffer(length: nextHeader.size)

                if nextHeader.type == SampleDescriptionBox.containerType {
                    sampleDescriptionBox = SampleDescriptionBox(buffer: nextBuffer, handlerType: handlerType)
                }
            }
            else {
                buffer.advance(length: nextHeader.size)
            }
        }

        self.sampleDescriptionBox = sampleDescriptionBox!
    }
}

extension SampleTableBox: CustomStringConvertible {
    var description: String {
        return "SampleTableBox(header: \(header), sampleDescriptionBox: \(sampleDescriptionBox))"
    }
}

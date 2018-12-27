import Foundation

struct MediaInformationBox {
    static let containerType = "minf"

    static let significantContainers = [
        SampleTableBox.containerType
    ]

    let header: BoxHeader
    let sampleTableBox: SampleTableBox
    let handlerType: MediaHandlerBox.HandlerType

    init(buffer: Buffer, handlerType: MediaHandlerBox.HandlerType) {
        self.header = buffer.readBoxHeader()
        self.handlerType = handlerType

        var sampleTableBox: SampleTableBox?

        while buffer.hasMoreBytes {
            let nextHeader = buffer.readBoxHeaderAndRewind()

            if MediaInformationBox.significantContainers.contains(nextHeader.type) {
                let nextBuffer = buffer.readBuffer(length: nextHeader.size)

                if nextHeader.type == SampleTableBox.containerType {
                    sampleTableBox = SampleTableBox(buffer: nextBuffer, handlerType: handlerType)
                }
            }
            else {
                buffer.advance(length: nextHeader.size)
            }
        }

        self.sampleTableBox = sampleTableBox!
    }
}

extension MediaInformationBox: CustomStringConvertible {
    var description: String {
        return "MediaInformationBox(header: \(header), sampleTableBox: \(sampleTableBox))"
    }
}

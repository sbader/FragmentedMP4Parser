import Foundation

struct TrackBox {
    static let containerType = "trak"

    static let significantContainers = [
        TrackHeaderBox.containerType,
        MediaBox.containerType
    ]

    let header: BoxHeader

    let trackHeaderBox: TrackHeaderBox
    let mediaBox: MediaBox

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()

        var trackHeaderBox: TrackHeaderBox? = nil
        var mediaBox: MediaBox? = nil

        while buffer.hasMoreBytes {
            let nextHeader = buffer.readBoxHeaderAndRewind()

            if TrackBox.significantContainers.contains(nextHeader.type) {
                let nextBuffer = buffer.readBuffer(length: nextHeader.size)

                if nextHeader.type == TrackHeaderBox.containerType {
                    trackHeaderBox = TrackHeaderBox(buffer: nextBuffer)
                }
                else if nextHeader.type == MediaBox.containerType {
                    mediaBox = MediaBox(buffer: nextBuffer)
                }
            }
            else {
                buffer.advance(length: nextHeader.size)
            }
        }

        self.trackHeaderBox = trackHeaderBox!
        self.mediaBox = mediaBox!
    }
}

extension TrackBox: CustomStringConvertible {
    var description: String {
        return "TrackBox(header: \(header), trackHeaderBox: \(trackHeaderBox), mediaBox: \(mediaBox))"
    }
}

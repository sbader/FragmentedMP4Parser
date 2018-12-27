import Foundation

struct TrackFragmentBox {
    static let containerType = "traf"

    static let significantContainers = [
        TrackFragmentHeaderBox.containerType,
        TrackRunBox.containerType
    ]

    let header: BoxHeader

    let trackFragmentHeaderBox: TrackFragmentHeaderBox
    let trackRunBoxes: [TrackRunBox]

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()

        var trackFragmentHeaderBox: TrackFragmentHeaderBox? = nil
        var trackRunBoxes: [TrackRunBox] = []

        while buffer.hasMoreBytes {
            let nextHeader = buffer.readBoxHeaderAndRewind()

            if TrackFragmentBox.significantContainers.contains(nextHeader.type) {
                let nextBuffer = buffer.readBuffer(length: nextHeader.size)

                if nextHeader.type == TrackFragmentHeaderBox.containerType {
                    trackFragmentHeaderBox = TrackFragmentHeaderBox(buffer: nextBuffer)
                }
                else if nextHeader.type == TrackRunBox.containerType {
                    let trackRunBox = TrackRunBox(buffer: nextBuffer)
                    trackRunBoxes.append(trackRunBox)
                }
            }
            else {
                buffer.advance(length: nextHeader.size)
            }
        }

        self.trackFragmentHeaderBox = trackFragmentHeaderBox!
        self.trackRunBoxes = trackRunBoxes
    }
}

extension TrackFragmentBox: CustomStringConvertible {
    var description: String {
        return "TrackFragmentBox(header: \(header), trackFragmentHeaderBox: \(trackFragmentHeaderBox), trackRunBoxes: \(trackRunBoxes))"
    }
}

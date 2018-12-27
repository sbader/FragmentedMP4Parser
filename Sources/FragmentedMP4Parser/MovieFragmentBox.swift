import Foundation

struct MovieFragmentBox {
    static let containerType = "moof"

    static let significantContainers = [
        MovieFragmentHeaderBox.containerType,
        TrackFragmentBox.containerType
    ]

    let header: BoxHeader

    let movieFragmentHeaderBox: MovieFragmentHeaderBox
    let trackFragmentBoxes: [TrackFragmentBox]

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()

        var movieFragmentHeaderBox: MovieFragmentHeaderBox? = nil
        var trackFragmentBoxes: [TrackFragmentBox] = []

        while buffer.hasMoreBytes {
            let nextHeader = buffer.readBoxHeaderAndRewind()

            if MovieFragmentBox.significantContainers.contains(nextHeader.type) {
                let nextBuffer = buffer.readBuffer(length: nextHeader.size)

                if nextHeader.type == MovieFragmentHeaderBox.containerType {
                    movieFragmentHeaderBox = MovieFragmentHeaderBox(buffer: nextBuffer)
                }
                else if nextHeader.type == TrackFragmentBox.containerType {
                    let trackFragmentBox = TrackFragmentBox(buffer: nextBuffer)
                    trackFragmentBoxes.append(trackFragmentBox)
                }
            }
            else {
                buffer.advance(length: nextHeader.size)
            }
        }

        self.movieFragmentHeaderBox = movieFragmentHeaderBox!
        self.trackFragmentBoxes = trackFragmentBoxes
    }
}

extension MovieFragmentBox: CustomStringConvertible {
    var description: String {
        return "MovieFragmentBox(header: \(header), movieFragmentHeaderBox: \(movieFragmentHeaderBox), trackFragmentBoxes: \(trackFragmentBoxes))"
    }
}

extension MovieFragmentBox {
    func trackFragmentBox(withID trackID: UInt32) -> TrackFragmentBox? {
        return trackFragmentBoxes.first(where: { (box) -> Bool in
            return box.trackFragmentHeaderBox.trackID == trackID
        })
    }
}

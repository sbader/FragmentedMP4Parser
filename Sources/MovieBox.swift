import Foundation

struct MovieBox {
    static let containerType = "moov"

    static let significantContainers = [
        MovieHeaderBox.containerType,
        TrackBox.containerType
    ]

    let header: BoxHeader
    let movieHeaderBox: MovieHeaderBox?
    let trackBoxes: [TrackBox]

    init(buffer: Buffer) {
        self.header = buffer.readBoxHeader()

        var movieHeaderBox: MovieHeaderBox? = nil
        var trackBoxes: [TrackBox] = []

        while buffer.hasMoreBytes {
            let nextHeader = buffer.readBoxHeaderAndRewind()

            if MovieBox.significantContainers.contains(nextHeader.type) {
                let nextBuffer = buffer.readBuffer(length: nextHeader.size)

                if nextHeader.type == MovieHeaderBox.containerType {
                    movieHeaderBox = MovieHeaderBox(buffer: nextBuffer)
                }
                else if nextHeader.type == TrackBox.containerType {
                    let trackBox = TrackBox(buffer: nextBuffer)
                    trackBoxes.append(trackBox)
                }
            }
            else {
                buffer.advance(length: nextHeader.size)
            }
        }

        self.movieHeaderBox = movieHeaderBox
        self.trackBoxes = trackBoxes
    }
}

extension MovieBox: CustomStringConvertible {
    var description: String {
        return "MovieBox(header: \(header), movieHeaderBox: \(String(describing: movieHeaderBox)), trackBoxes: \(trackBoxes))"
    }
}

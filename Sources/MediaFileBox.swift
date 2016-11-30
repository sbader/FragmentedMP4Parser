import Foundation

struct MediaFileBox {
    var fileTypeBox: FileTypeBox?
    var movieBox: MovieBox?
    var movieFragmentBoxes: [MovieFragmentBox] = []
    var mediaDataBoxesInfo: [MediaDataBoxInfo] = []
}

extension MediaFileBox: CustomStringConvertible {
    var description: String {
        return "MediaFile(fileTypeBox: \(fileTypeBox), movieBox: \(movieBox), movieFragmentBoxes: \(movieFragmentBoxes))"
    }
}

extension MediaFileBox {
    var videoTrack: TrackBox? {
        return movieBox?.trackBoxes.first { (trackBox) -> Bool in
            return trackBox.mediaBox.handlerBox.type == .Video
        }
    }

    var audioTrack: TrackBox? {
        return movieBox?.trackBoxes.first { (trackBox) -> Bool in
            return trackBox.mediaBox.handlerBox.type == .Audio
        }
    }
}

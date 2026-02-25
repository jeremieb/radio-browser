import Foundation

/// Holds the matched track data returned by ShazamService.
/// Decouples views from the ShazamKit framework types.
struct ShazamResult: Equatable {
    let title: String
    let artist: String?
    let album: String?
    let artworkURL: URL?
    let appleMusicURL: URL?
}

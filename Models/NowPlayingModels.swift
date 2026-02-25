import Foundation

// MARK: - Shared snapshot passed from NowPlayingViewModel → RadioPlayerViewModel

struct NowPlayingSnapshot {
    let title: String
    let subtitle: String?
    let artworkURL: URL?
    let errorMessage: String?
}

// MARK: - NTS Radio API

struct NTSNowPlayingResponse: Decodable {
    let results: [NTSLiveChannel]
}

struct NTSLiveChannel: Decodable {
    let channelName: String?
    let now: NTSBroadcast?
    let upcoming: [NTSBroadcast]

    private enum CodingKeys: String, CodingKey {
        case channelName = "channel_name"
        case now
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)

        channelName = try container.decodeIfPresent(String.self, forKey: .channelName)
        now = try container.decodeIfPresent(NTSBroadcast.self, forKey: .now)

        var upcomingPairs: [(Int, NTSBroadcast)] = []

        for key in dynamicContainer.allKeys where key.stringValue.hasPrefix("next") {
            guard let broadcast = try? dynamicContainer.decode(NTSBroadcast.self, forKey: key) else {
                continue
            }

            let suffix = String(key.stringValue.dropFirst(4))
            let order = Int(suffix) ?? 1
            upcomingPairs.append((order, broadcast))
        }

        upcoming = upcomingPairs
            .sorted { lhs, rhs in lhs.0 < rhs.0 }
            .map { pair in pair.1 }
    }
}

struct NTSBroadcast: Decodable {
    let broadcastTitle: String?
    let startTimestamp: String?
    let endTimestamp: String?
    let embeds: NTSEmbeds?
    let links: [NTSLink]?

    private enum CodingKeys: String, CodingKey {
        case broadcastTitle = "broadcast_title"
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
        case embeds
        case links
    }
}

struct NTSEmbeds: Decodable {
    let details: NTSEpisodeDetails?
}

struct NTSEpisodeDetails: Decodable {
    let status: String?
    let updated: String?
    let name: String?
    let description: String?
    let descriptionHTML: String?
    let locationShort: String?
    let locationLong: String?
    let intensity: String?
    let media: NTSMedia?

    private enum CodingKeys: String, CodingKey {
        case status
        case updated
        case name
        case description
        case descriptionHTML = "description_html"
        case locationShort = "location_short"
        case locationLong = "location_long"
        case intensity
        case media
    }
}

struct NTSMedia: Decodable {
    let backgroundLarge: URL?
    let backgroundMediumLarge: URL?
    let backgroundMedium: URL?
    let backgroundSmall: URL?
    let backgroundThumb: URL?
    let pictureLarge: URL?
    let pictureMediumLarge: URL?
    let pictureMedium: URL?
    let pictureSmall: URL?
    let pictureThumb: URL?

    private enum CodingKeys: String, CodingKey {
        case backgroundLarge = "background_large"
        case backgroundMediumLarge = "background_medium_large"
        case backgroundMedium = "background_medium"
        case backgroundSmall = "background_small"
        case backgroundThumb = "background_thumb"
        case pictureLarge = "picture_large"
        case pictureMediumLarge = "picture_medium_large"
        case pictureMedium = "picture_medium"
        case pictureSmall = "picture_small"
        case pictureThumb = "picture_thumb"
    }
}

struct NTSLink: Decodable {
    let href: URL?
    let rel: String?
    let type: String?
}

// MARK: - Worldwide FM API

struct WorldwideNowPlayingResponse: Decodable {
    let success: Bool
    let result: WorldwideNowPlayingResult?
}

struct WorldwideNowPlayingResult: Decodable {
    let status: String?
    let content: WorldwideNowPlayingContent?
    let metadata: WorldwideNowPlayingMetadata?
}

struct WorldwideNowPlayingContent: Decodable {
    let title: String?
    let color: String?
    let media: WorldwideNowPlayingMedia?
}

struct WorldwideNowPlayingMetadata: Decodable {
    let title: String?
    let artist: String?
    let album: String?
}

struct WorldwideNowPlayingMedia: Decodable {
    let type: String?
}

// MARK: - FIP (Radio France) API

struct FIPNowPlayingResponse: Decodable {
    let steps: [String: FIPStep]
    let levels: [FIPLevel]
}

struct FIPLevel: Decodable {
    let items: [String]
    let position: Int
}

struct FIPStep: Decodable {
    let title: String?
    let highlightedArtists: [String]?
    let authors: String?
    let titreAlbum: String?
    let visual: URL?
    let start: TimeInterval?
    let end: TimeInterval?
}

// MARK: - Helpers

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

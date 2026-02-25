import Foundation

struct Radio {
    let name: String?
    let streamURL: URL?
    let nowPlayingAPI: URL?
    let image: String?
    let description: String?
    let disable: Bool?
}

let MyRadios: [Radio] = [
    Radio(
        name: "NTS 1",
        streamURL: URL(string: "https://stream-relay-geo.ntslive.net/stream")!,
        nowPlayingAPI: URL(string: "https://www.nts.live/api/v2/live")!,
        image: "nts-radio",
        description: "NTS Radio (also known as NTS Live or simply NTS) is a music radio platform which was founded in 2011 in Hackney, East London by Femi Adeyemi \"for an international community of music lovers\" The platform prioritizes showcasing niche artists in its radio programming and live events. NTS Radio's tagline is \"Don't Assume\".",
        disable: false
    ),
    Radio(
        name: "NTS 2",
        streamURL: URL(string: "https://stream-relay-geo.ntslive.net/stream2")!,
        nowPlayingAPI: URL(string: "https://www.nts.live/api/v2/live")!,
        image: "nts-radio",
        description: "NTS Radio (also known as NTS Live or simply NTS) is a music radio platform which was founded in 2011 in Hackney, East London by Femi Adeyemi \"for an international community of music lovers\" The platform prioritizes showcasing niche artists in its radio programming and live events. NTS Radio's tagline is \"Don't Assume\".",
        disable: false
    ),
    Radio(
        name: "Worldwide FM",
        streamURL: URL(string: "https://worldwide-fm.radiocult.fm/stream")!,
        nowPlayingAPI: URL(string: "https://api.radiocult.fm/api/station/worldwide-fm/schedule/live")!,
        image: "worldwide-fm-radio",
        description: "Worldwide FM curates and champions underground music, stories and culture from around the world.",
        disable: false
    ),
    Radio(
        name: "FIP",
        streamURL: URL(string: "https://icecast.radiofrance.fr/fip-hifi.aac?id=radiofrance")!,
        nowPlayingAPI: URL(string: "https://api.radiofrance.fr/livemeta/pull/7")!,
        image: "fip-radio",
        description: "All music programming is hand-picked by a small team of curators, who create three-hour blocks of music. They abide by a few rules, most notably paying close attention to how tracks transition from one to the other, across genres and styles, and especially making sure that a song is never played twice in a 48-hour window.",
        disable: false
    )
]

import Foundation

@MainActor
final class NowPlayingViewModel: ObservableObject {
    @Published private(set) var title = "Not playing"
    @Published private(set) var subtitle: String?
    @Published private(set) var artworkURL: URL?
    @Published private(set) var errorMessage: String?

    var onUpdate: ((NowPlayingSnapshot) -> Void)?

    private var updateTask: Task<Void, Never>?

    func startUpdating(for radio: Radio) {
        stopUpdating(resetState: false)

        if let icyURL = radio.icyStreamURL {
            // ICY in-stream metadata: open the stream, grab the title, repeat.
            updateTask = Task {
                await refreshICY(url: icyURL, radio: radio)
                while !Task.isCancelled {
                    // Wait a bit before re-connecting to detect track changes.
                    try? await Task.sleep(nanoseconds: 15_000_000_000) // 15 s
                    guard !Task.isCancelled else { break }
                    await refreshICY(url: icyURL, radio: radio)
                }
            }
            return
        }

        guard radio.nowPlayingAPI != nil else {
            title = radio.name ?? "Live"
            subtitle = "No now-playing endpoint"
            artworkURL = nil
            errorMessage = nil
            publishUpdate()
            return
        }

        updateTask = Task {
            await refresh(for: radio)

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled else { break }
                await refresh(for: radio)
            }
        }
    }

    func stopUpdating(resetState: Bool) {
        updateTask?.cancel()
        updateTask = nil

        if resetState {
            title = "Not playing"
            subtitle = nil
            artworkURL = nil
            errorMessage = nil
            publishUpdate()
        }
    }

    func setStoppedState() {
        title = "Stopped"
        subtitle = nil
        errorMessage = nil
        publishUpdate()
    }

    private func refresh(for radio: Radio) async {
        guard let endpoint = radio.nowPlayingAPI else {
            title = radio.name ?? "Live"
            subtitle = "No now-playing endpoint"
            artworkURL = nil
            errorMessage = nil
            publishUpdate()
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: endpoint)
            let decoder = JSONDecoder()

            if let ntsResponse = try? decoder.decode(NTSNowPlayingResponse.self, from: data) {
                applyNTSNowPlaying(ntsResponse, radio: radio)
                return
            }

            if let worldwideResponse = try? decoder.decode(WorldwideNowPlayingResponse.self, from: data) {
                applyWorldwideNowPlaying(worldwideResponse, radio: radio)
                return
            }

            if let fipResponse = try? decoder.decode(FIPNowPlayingResponse.self, from: data) {
                applyFIPNowPlaying(fipResponse, radio: radio)
                return
            }

            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "Unsupported now-playing response format")
            )
        } catch {
            title = radio.name ?? "Live"
            subtitle = "Unable to fetch now playing"
            artworkURL = nil
            errorMessage = error.localizedDescription
            publishUpdate()
        }
    }

    private func applyNTSNowPlaying(_ response: NTSNowPlayingResponse, radio: Radio) {
        let channel = bestChannelMatch(in: response.results, for: radio)
        let now = channel?.now
        let details = now?.embeds?.details

        title = details?.name ?? now?.broadcastTitle?.htmlDecoded ?? (radio.name ?? "Live")
        subtitle = details?.name != nil ? now?.broadcastTitle?.htmlDecoded : nil
        artworkURL = details?.media?.pictureMedium ?? details?.media?.backgroundMedium
        errorMessage = nil
        publishUpdate()
    }

    private func applyWorldwideNowPlaying(_ response: WorldwideNowPlayingResponse, radio: Radio) {
        let content = response.result?.content
        let metadata = response.result?.metadata

        title = content?.title ?? metadata?.title ?? (radio.name ?? "Live")
        subtitle = metadata?.artist ?? metadata?.title ?? response.result?.status
        artworkURL = nil
        errorMessage = nil
        publishUpdate()
    }

    private func applyFIPNowPlaying(_ response: FIPNowPlayingResponse, radio: Radio) {
        // Use levels[0].position to find the current step ID, then look it up in steps.
        let step: FIPStep? = {
            guard let level = response.levels.first else { return nil }
            let index = level.position
            guard index >= 0, index < level.items.count else { return nil }
            let stepId = level.items[index]
            return response.steps[stepId]
        }()

        let artist = step?.highlightedArtists?.first ?? step?.authors
        title = step?.title ?? (radio.name ?? "Live")
        subtitle = artist
        artworkURL = step?.visual
        errorMessage = nil
        publishUpdate()
    }

    private func refreshICY(url: URL, radio: Radio) async {
        do {
            let streamTitle = try await ICYMetadataService.fetchTitle(from: url)
            // StreamTitle is often "Artist - Title" — split on the first " - ".
            if let separatorRange = streamTitle.range(of: " - ") {
                title = String(streamTitle[separatorRange.upperBound...])
                subtitle = String(streamTitle[..<separatorRange.lowerBound])
            } else {
                title = streamTitle
                subtitle = radio.name
            }
            artworkURL = nil
            errorMessage = nil
        } catch {
            title = radio.name ?? "Live"
            subtitle = nil
            artworkURL = nil
            errorMessage = nil
        }
        publishUpdate()
    }

    private func publishUpdate() {
        onUpdate?(
            NowPlayingSnapshot(
                title: title,
                subtitle: subtitle,
                artworkURL: artworkURL,
                errorMessage: errorMessage
            )
        )
    }

    private func bestChannelMatch(in channels: [NTSLiveChannel], for radio: Radio) -> NTSLiveChannel? {
        if let directMatch = channels.first(where: { $0.channelName == inferredChannelName(for: radio) }) {
            return directMatch
        }

        return channels.first
    }

    private func inferredChannelName(for radio: Radio) -> String {
        guard let name = radio.name else { return "1" }
        return name.contains("2") ? "2" : "1"
    }
}

import SwiftUI

struct NowPlayingSnapshot {
    let title: String
    let subtitle: String?
    let artworkURL: URL?
    let errorMessage: String?
}

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
            let response = try JSONDecoder().decode(NTSNowPlayingResponse.self, from: data)

            let channel = bestChannelMatch(in: response.results, for: radio)
            let now = channel?.now
            let details = now?.embeds?.details

            title = details?.name ?? now?.broadcastTitle ?? (radio.name ?? "Live")
            subtitle = now?.broadcastTitle
            artworkURL = details?.media?.pictureMedium ?? details?.media?.backgroundMedium
            errorMessage = nil
            publishUpdate()
        } catch {
            title = radio.name ?? "Live"
            subtitle = "Unable to fetch now playing"
            artworkURL = nil
            errorMessage = error.localizedDescription
            publishUpdate()
        }
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

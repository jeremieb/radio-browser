#if os(macOS)
import AVFoundation

@MainActor
final class RadioPlayerViewModel: ObservableObject {
    @Published var selectedStationIndex = 0
    @Published var isPlaying = false
    @Published var nowPlayingTitle = "Not playing"
    @Published var nowPlayingSubtitle: String?
    @Published var nowPlayingArtworkURL: URL?
    @Published var nowPlayingErrorMessage: String?

    let nowPlaying = NowPlayingViewModel()

    private var player: AVPlayer?
    private let systemNowPlaying = SystemNowPlayingCenter()

    init() {
        nowPlaying.onUpdate = { [weak self] snapshot in
            self?.applyNowPlaying(snapshot)
            self?.publishNowPlaying(snapshot: snapshot)
        }

        systemNowPlaying.configureRemoteCommands(
            onPlay: { [weak self] in
                self?.resumeOrPlaySelectedStation()
                return .success
            },
            onPause: { [weak self] in
                self?.pause()
                return .success
            },
            onStop: { [weak self] in
                self?.stop()
                return .success
            }
        )
    }

    func playStation(at index: Int) {
        guard MyRadios.indices.contains(index) else { return }
        selectedStationIndex = index
        playSelectedStation()
    }

    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            resumeOrPlaySelectedStation()
        }
    }

    func playSelectedStation() {
        guard MyRadios.indices.contains(selectedStationIndex) else {
            return
        }

        let radio = MyRadios[selectedStationIndex]

        guard let streamURL = radio.streamURL else {
            return
        }

        if player != nil {
            stopPlayback(resetNowPlaying: true)
        }

        let item = AVPlayerItem(url: streamURL)
        player = AVPlayer(playerItem: item)
        player?.play()

        isPlaying = true
        publishNowPlaying(snapshot: nil)
        nowPlaying.startUpdating(for: radio)
    }

    func pause() {
        guard let player else { return }
        player.pause()
        isPlaying = false
        publishNowPlaying(snapshot: nil)
    }

    func stop() {
        stopPlayback(resetNowPlaying: false)
        nowPlaying.setStoppedState()
        publishNowPlaying(snapshot: nil)
    }

    private func resumeOrPlaySelectedStation() {
        if let player {
            player.play()
            isPlaying = true
            publishNowPlaying(snapshot: nil)
        } else {
            playSelectedStation()
        }
    }

    private func stopPlayback(resetNowPlaying: Bool) {
        player?.pause()
        player = nil
        isPlaying = false

        if resetNowPlaying {
            nowPlaying.stopUpdating(resetState: true)
        } else {
            nowPlaying.stopUpdating(resetState: false)
        }

        if !isPlaying {
            systemNowPlaying.clear()
        }
    }

    private func applyNowPlaying(_ snapshot: NowPlayingSnapshot) {
        nowPlayingTitle = snapshot.title
        nowPlayingSubtitle = snapshot.subtitle
        nowPlayingArtworkURL = snapshot.artworkURL
        nowPlayingErrorMessage = snapshot.errorMessage
    }

    private func publishNowPlaying(snapshot: NowPlayingSnapshot?) {
        guard MyRadios.indices.contains(selectedStationIndex) else { return }

        let radio = MyRadios[selectedStationIndex]
        let currentTitle = snapshot?.title ?? nowPlayingTitle
        let currentSubtitle = snapshot?.subtitle ?? nowPlayingSubtitle
        let currentArtworkURL = snapshot?.artworkURL ?? nowPlayingArtworkURL

        systemNowPlaying.update(
            stationName: radio.name,
            title: currentTitle,
            subtitle: currentSubtitle,
            artworkURL: currentArtworkURL,
            isPlaying: isPlaying
        )
    }
}
#endif

import AVFoundation
import SwiftUI

@MainActor
final class RadioPlayerViewModel: ObservableObject {

    private static let audioSessionConfigured: Bool = {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                policy: .longFormAudio,
                options: []
            )
            try session.setActive(true)
        } catch {
            // Audio session setup failed; playback may not continue in background.
        }
        #endif
        return true
    }()

    // MARK: - Published state

    @Published var selectedStationIndex = 0
    @Published var isPlaying = false
    @Published var nowPlayingTitle = "Not playing"
    @Published var nowPlayingSubtitle: String?
    @Published var nowPlayingArtworkURL: URL?
    @Published var nowPlayingErrorMessage: String?

    /// Artwork-derived palette used to tint the animated blob background.
    @Published var blobPalette: [Color] = defaultBlobPalette
    /// Vinyl disc rotation angle, driven by an internal 60 fps task while playing.
    @Published var vinylRotation: Double = 0
    /// Controls now-playing panel visibility with an automatic 2-second hide delay on pause.
    @Published var showNowPlaying: Bool = false

    // MARK: - Dependencies

    let nowPlaying: NowPlayingProviding
    private let systemNowPlaying: SystemNowPlayingProviding

    /// Production init — creates default concrete dependencies.
    convenience init() {
        self.init(nowPlaying: NowPlayingViewModel(), systemNowPlaying: SystemNowPlayingCenter())
        RadioPlaybackCoordinator.shared.activePlayer = self
    }

    /// Designated init for testing — accepts injectable dependencies.
    init(nowPlaying: NowPlayingProviding, systemNowPlaying: SystemNowPlayingProviding) {
        self.nowPlaying = nowPlaying
        self.systemNowPlaying = systemNowPlaying
        _ = Self.audioSessionConfigured

        nowPlaying.onUpdate = { [weak self] snapshot in
            self?.applyNowPlaying(snapshot)
            self?.publishNowPlaying(snapshot: snapshot)
        }

        systemNowPlaying.configureRemoteCommands(
            onPlay: { [weak self] in
                Task { @MainActor [weak self] in self?.resumeOrPlaySelectedStation() }
                return .success
            },
            onPause: { [weak self] in
                Task { @MainActor [weak self] in self?.pause() }
                return .success
            },
            onStop: { [weak self] in
                Task { @MainActor [weak self] in self?.stop() }
                return .success
            },
            onToggle: { [weak self] in
                Task { @MainActor [weak self] in self?.togglePlayback() }
                return .success
            }
        )
    }

    // MARK: - Playback

    private var player: AVPlayer?

    func playStation(at index: Int) {
        guard MyRadios.indices.contains(index) else { return }
        selectedStationIndex = index
        playSelectedStation()
    }

    func playStation(byID id: String) {
        guard let index = MyRadios.firstIndex(where: { $0.id == id }) else { return }
        playStation(at: index)
    }

    func togglePlayback() {
        if isPlaying {
            pause()
        } else {
            resumeOrPlaySelectedStation()
        }
    }

    func playSelectedStation() {
        guard MyRadios.indices.contains(selectedStationIndex) else { return }
        let radio = MyRadios[selectedStationIndex]
        guard let streamURL = radio.streamURL else { return }

        if player != nil {
            stopPlayback(resetNowPlaying: true)
        }

        let item = AVPlayerItem(url: streamURL)
        player = AVPlayer(playerItem: item)
        player?.play()

        isPlaying = true
        updatePresentationState(isNowPlaying: true)
        publishNowPlaying(snapshot: nil)
        nowPlaying.startUpdating(for: radio)
    }

    func pause() {
        guard let player else { return }
        player.pause()
        isPlaying = false
        updatePresentationState(isNowPlaying: false)
        systemNowPlaying.markPaused()
    }

    func stop() {
        stopPlayback(resetNowPlaying: false)
        updatePresentationState(isNowPlaying: false)
        nowPlaying.setStoppedState()
        publishNowPlaying(snapshot: nil)
    }

    private func resumeOrPlaySelectedStation() {
        if let player {
            player.play()
            isPlaying = true
            updatePresentationState(isNowPlaying: true)
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

        if snapshot.artworkURL != nil {
            hideTask?.cancel()
            showNowPlaying = true
        }

        paletteTask?.cancel()
        paletteTask = Task { await updateBlobPalette(from: snapshot.artworkURL) }
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

    // MARK: - Presentation state

    private var vinylTask: Task<Void, Never>?
    private var hideTask: Task<Void, Never>?

    private func updatePresentationState(isNowPlaying: Bool) {
        vinylTask?.cancel()
        if isNowPlaying {
            hideTask?.cancel()
            showNowPlaying = true
            vinylTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 16_000_000) // ~60 fps
                    vinylRotation += 0.6
                }
            }
        } else {
            hideTask?.cancel()
            hideTask = Task {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                showNowPlaying = false
            }
        }
    }

    // MARK: - Blob palette

    private var paletteTask: Task<Void, Never>?

    private func updateBlobPalette(from url: URL?) async {
        guard let url else { blobPalette = defaultBlobPalette; return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
        guard !Task.isCancelled else { return }
        let palette = extractPalette(from: data)
        if !palette.isEmpty { blobPalette = palette }
    }
}

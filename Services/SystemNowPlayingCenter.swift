import Foundation
import MediaPlayer

#if os(iOS)
import UIKit
private typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
private typealias PlatformImage = NSImage
#endif

@MainActor
final class SystemNowPlayingCenter {
    private let infoCenter = MPNowPlayingInfoCenter.default()
    private var nowPlayingInfo: [String: Any] = [:]
    private var artworkTask: Task<Void, Never>?
    private var remoteCommandsConfigured = false

    func configureRemoteCommands(
        onPlay: @escaping () -> MPRemoteCommandHandlerStatus,
        onPause: @escaping () -> MPRemoteCommandHandlerStatus,
        onStop: @escaping () -> MPRemoteCommandHandlerStatus
    ) {
        guard !remoteCommandsConfigured else { return }
        remoteCommandsConfigured = true

        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.stopCommand.isEnabled = true

        commandCenter.playCommand.addTarget { _ in onPlay() }
        commandCenter.pauseCommand.addTarget { _ in onPause() }
        commandCenter.stopCommand.addTarget { _ in onStop() }
    }

    func update(
        stationName: String?,
        title: String,
        subtitle: String?,
        artworkURL: URL?,
        isPlaying: Bool
    ) {
        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = stationName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = subtitle
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true

        if #available(macOS 10.13, iOS 11.1, *) {
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        }

        infoCenter.nowPlayingInfo = nowPlayingInfo
        infoCenter.playbackState = isPlaying ? .playing : .paused

        updateArtwork(from: artworkURL)
    }

    func clear() {
        artworkTask?.cancel()
        artworkTask = nil
        nowPlayingInfo.removeAll()
        infoCenter.nowPlayingInfo = nil
        infoCenter.playbackState = .stopped
    }

    private func updateArtwork(from artworkURL: URL?) {
        artworkTask?.cancel()
        artworkTask = nil

        guard let artworkURL else {
            nowPlayingInfo.removeValue(forKey: MPMediaItemPropertyArtwork)
            infoCenter.nowPlayingInfo = nowPlayingInfo
            return
        }

        artworkTask = Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: artworkURL)
                guard let image = PlatformImage(data: data) else { return }

                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in
                    image
                }

                nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                infoCenter.nowPlayingInfo = nowPlayingInfo
            } catch {
                // Keep existing now-playing metadata without artwork on failure.
            }
        }
    }
}

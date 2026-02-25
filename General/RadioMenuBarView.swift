#if os(macOS)
import SwiftUI
import AVFoundation
import AVKit
import AppKit

struct RadioMenuBarView: View {
    @StateObject private var player = RadioPlayerViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Radio Browser")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(MyRadios.enumerated()), id: \.offset) { index, radio in
                        stationCard(for: radio, index: index)
                    }
                }
                .padding(.vertical, 2)
            }

            HStack(spacing: 8) {
                Button(player.isPlaying ? "Playing" : "Play") {
                    player.playSelectedStation()
                }
                .disabled(player.isPlaying || MyRadios.isEmpty)

                Button("Stop") {
                    player.stop()
                }
                .disabled(!player.isPlaying)

                Spacer()

                AirPlayRoutePickerView()
                    .frame(width: 26, height: 26)
            }

            VStack(alignment: .leading, spacing: 8) {
                if let artworkURL = player.nowPlaying.artworkURL {
                    AsyncImage(url: artworkURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            fallbackArtwork
                        case .empty:
                            ProgressView()
                        @unknown default:
                            fallbackArtwork
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    fallbackArtwork
                        .frame(width: 64, height: 64)
                }

                Text(player.nowPlaying.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                if let subtitle = player.nowPlaying.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let errorMessage = player.nowPlaying.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(width: 320)
    }

    @ViewBuilder
    private func stationCard(for radio: Radio, index: Int) -> some View {
        let isSelected = player.selectedStationIndex == index

        Button {
            player.selectedStationIndex = index
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                stationThumbnail(for: radio)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(radio.name ?? "Station \(index + 1)")
                    .font(.caption)
                    .lineLimit(1)
                    .frame(width: 64, alignment: .leading)
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(radio.disable ?? false)
    }

    @ViewBuilder
    private func stationThumbnail(for radio: Radio) -> some View {
        if let imageName = radio.image, !imageName.isEmpty, NSImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
                .overlay {
                    Image(systemName: "radio")
                        .foregroundStyle(.secondary)
                }
        }
    }

    private var fallbackArtwork: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.secondary.opacity(0.15))
            .overlay {
                Image(systemName: "music.note")
                    .foregroundStyle(.secondary)
            }
    }
}

@MainActor
final class RadioPlayerViewModel: ObservableObject {
    @Published var selectedStationIndex = 0
    @Published var isPlaying = false

    let nowPlaying = NowPlayingViewModel()

    private var player: AVPlayer?

    func playSelectedStation() {
        guard MyRadios.indices.contains(selectedStationIndex) else {
            return
        }

        let radio = MyRadios[selectedStationIndex]

        guard let streamURL = radio.streamURL else {
            return
        }

        stopPlayback(resetNowPlaying: true)

        let item = AVPlayerItem(url: streamURL)
        player = AVPlayer(playerItem: item)
        player?.play()

        isPlaying = true
        nowPlaying.startUpdating(for: radio)
    }

    func stop() {
        stopPlayback(resetNowPlaying: false)
        nowPlaying.setStoppedState()
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
    }
}

struct AirPlayRoutePickerView: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.setRoutePickerButtonColor(.labelColor, for: .normal)
        view.setRoutePickerButtonColor(.controlAccentColor, for: .active)
        return view
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
    }
}

#Preview {
    RadioMenuBarView()
}
#endif

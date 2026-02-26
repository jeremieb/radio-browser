#if os(macOS)
import SwiftUI
import AppKit

struct NowPlayingView: View {
    @ObservedObject var player: RadioPlayerViewModel
    let vinylRotation: Double
    let shazamPulse: Bool
    let analytics: Analytics
    @Environment(ShazamService.self) private var shazam

    var body: some View {
        ZStack(alignment: .trailing) {
            vinylDisc
                .frame(width: 210, height: 210)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 14, y: 8)
                .rotationEffect(.degrees(vinylRotation))

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading) {
                    Text(player.nowPlayingTitle)
                        .font(.body).fontWidth(.expanded).fontWeight(.bold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.65), radius: 8, x: 0, y: 3)

                    if let subtitle = player.nowPlayingSubtitle {
                        Text(subtitle)
                            .font(.footnote).fontWeight(.medium)
                            .lineLimit(2)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.65), radius: 8, x: 0, y: 3)
                    }
                }.padding(.top)

                Spacer(minLength: 0)

                HStack(spacing: 22) {
                    ShazamButtonView(shazamPulse: shazamPulse, analytics: analytics)

                    Button {
                        player.togglePlayback()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)

                    AirPlayRoutePickerView()
                        .frame(width: 44, height: 44)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: 460, maxHeight: 460, alignment: .bottom).padding(.horizontal)
    }

    // MARK: - Vinyl disc

    @ViewBuilder
    private var vinylDisc: some View {
        if let artworkURL = player.nowPlayingArtworkURL {
            AsyncImage(url: artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    ProgressView()
                default:
                    stationFallbackImage
                }
            }
        } else {
            stationFallbackImage
        }
    }

    @ViewBuilder
    private var stationFallbackImage: some View {
        let radio = MyRadios.indices.contains(player.selectedStationIndex)
            ? MyRadios[player.selectedStationIndex] : nil
        if let imageName = radio?.image, !imageName.isEmpty, NSImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            Circle()
                .fill(Color.white.opacity(0.22))
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
        }
    }
}

// MARK: - Shazam button

private struct ShazamButtonView: View {
    let shazamPulse: Bool
    let analytics: Analytics
    @Environment(ShazamService.self) private var shazam

    var body: some View {
        Button {
            if shazam.isListening {
                shazam.cancel()
            } else {
                shazam.startListening()
            }
            analytics.sendSignal(signal: "shazam", parameters: nil)
        } label: {
            Image(systemName: "shazam.logo.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(shazam.isListening ? Color.cyan : Color.white)
                .frame(width: 44, height: 44)
                .scaleEffect(shazamPulse ? 1.18 : 1.0)
                .shadow(color: shazam.isListening ? Color.cyan.opacity(0.6) : Color.black.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .help(shazam.isListening ? "Listening… tap to cancel" : "Identify with Shazam")
    }
}
#endif

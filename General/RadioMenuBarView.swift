#if os(macOS)
import SwiftUI
import AVFoundation
import AVKit
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct RadioMenuBarView: View {
    @StateObject private var player = RadioPlayerViewModel()
    @State private var coverTint: Color = Color(red: 0.42, green: 0.58, blue: 0.86)

    private var isExpandedPlayer: Bool {
        player.isPlaying || player.nowPlayingArtworkURL != nil
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading) {
                header

                stationStrip

                if isExpandedPlayer {
                    expandedPlayerContent
                }
            }
            .frame(maxWidth: 420, maxHeight: 420, alignment: .topLeading)
            .padding(16)
        }
        .task(id: player.nowPlayingArtworkURL) {
            await refreshCoverTint()
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            if isExpandedPlayer {
                LinearGradient(
                    colors: [coverTint.opacity(0.78), coverTint.opacity(0.22), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            if let artworkURL = player.nowPlayingArtworkURL, isExpandedPlayer {
                AsyncImage(url: artworkURL) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .opacity(0.42)
                            .blur(radius: 2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .mask(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.25), .black.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
        }
        .frame(maxWidth: 420, maxHeight: 420)
        .background(.ultraThinMaterial)
    }

    private var header: some View {
        HStack {
            Text("Radio Browser")
                .font(.title).fontWeight(.bold).fontWidth(.expanded)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .white.opacity(0.35), radius: 3, y: -1)
            }
            .buttonStyle(.plain)
            .help("Quit Radio Browser")
        }
    }

    private var stationStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(MyRadios.enumerated()), id: \.offset) { index, radio in
                    stationCard(for: radio, index: index)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var expandedPlayerContent: some View {
        ZStack(alignment: .trailing) {
            if let artworkURL = player.nowPlayingArtworkURL {
                AsyncImage(url: artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        artworkFallback
                    case .empty:
                        ProgressView()
                    @unknown default:
                        artworkFallback
                    }
                }
                .frame(width: 210, height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 14, y: 8)
            }
            
            
            VStack(alignment: .leading, spacing: 8) {
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

                Spacer(minLength: 0)

                HStack(spacing: 22) {
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
        }.frame(maxWidth: 420, maxHeight: 420, alignment: .bottom)
    }

    @ViewBuilder
    private func stationCard(for radio: Radio, index: Int) -> some View {
        let isSelected = player.selectedStationIndex == index

        Button {
            player.playStation(at: index)
        } label: {
            stationThumbnail(for: radio)
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1)
                )
                .opacity(radio.disable ?? false ? 0.4 : 1)
                .shadow(color: isSelected ? Color.black.opacity(0.8) : Color.clear, radius: 4)
                .scaleEffect(isSelected ? 1.1 : 1)
        }
        .buttonStyle(.plain)
        .disabled(radio.disable ?? false)
        .padding(8)
    }

    @ViewBuilder
    private func stationThumbnail(for radio: Radio) -> some View {
        if let imageName = radio.image, !imageName.isEmpty, NSImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.32, green: 0.39, blue: 0.72))
        }
    }

    private var artworkFallback: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.22))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
    }

    private func refreshCoverTint() async {
        guard let artworkURL = player.nowPlayingArtworkURL else {
            coverTint = Color(red: 0.42, green: 0.58, blue: 0.86)
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: artworkURL)
            guard let image = NSImage(data: data),
                  let average = image.averageColor else {
                return
            }

            await MainActor.run {
                coverTint = Color(nsColor: average)
            }
        } catch {
            // Keep the existing tint when color extraction fails.
        }
    }
}

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

struct AirPlayRoutePickerView: NSViewRepresentable {
    func makeNSView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.isRoutePickerButtonBordered = false
        view.setRoutePickerButtonColor(.white, for: .normal)
        view.setRoutePickerButtonColor(.white, for: .active)
        return view
    }

    func updateNSView(_ nsView: AVRoutePickerView, context: Context) {
    }
}

private extension NSImage {
    var averageColor: NSColor? {
        guard let tiffData = tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else {
            return nil
        }

        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage
        filter.extent = ciImage.extent

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let context = CIContext(options: [.workingColorSpace: NSNull()])
        var pixel = [UInt8](repeating: 0, count: 4)

        context.render(
            outputImage,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return NSColor(
            calibratedRed: CGFloat(pixel[0]) / 255.0,
            green: CGFloat(pixel[1]) / 255.0,
            blue: CGFloat(pixel[2]) / 255.0,
            alpha: 1.0
        )
    }
}

#Preview {
    RadioMenuBarView()
}
#endif

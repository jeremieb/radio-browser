#if os(macOS)
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit

struct RadioMenuBarView: View {
    
    @StateObject private var player = RadioPlayerViewModel()
    @State private var coverTint: Color = Color(red: 0.42, green: 0.58, blue: 0.86)
    @Environment(ShazamService.self) private var shazam
    @Environment(\.openWindow) private var openWindow
    @State private var shazamPulse = false
    @State private var vinylRotation: Double = 0
    @State private var vinylAnimationTask: Task<Void, Never>?
    
    let analytics = Analytics.shared

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

                if let message = shazam.statusMessage {
                    shazamStatusFooter(message: message)
                }
            }
            .frame(maxWidth: 460, maxHeight: 460, alignment: .topLeading)
            .padding(16)
        }
        .task(id: player.nowPlayingArtworkURL) {
            await refreshCoverTint()
        }
        .onChange(of: player.isPlaying) { _, isPlaying in
            vinylAnimationTask?.cancel()
            if isPlaying {
                vinylAnimationTask = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 16_000_000) // ~60 fps
                        vinylRotation += 0.6
                    }
                }
            }
        }
        .onChange(of: shazam.state) { _, newState in
            switch newState {
            case .listening:
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    shazamPulse = true
                }
            case .matched:
                withAnimation(.default) { shazamPulse = false }
                openWindow(id: "shazam-result")
            default:
                withAnimation(.default) { shazamPulse = false }
            }
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
        .frame(maxWidth: 460, maxHeight: 460)
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
                    shazamButton

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
        }.frame(maxWidth: 460, maxHeight: 460, alignment: .bottom)
    }

    @ViewBuilder
    private func stationCard(for radio: Radio, index: Int) -> some View {
        let isSelected = player.selectedStationIndex == index

        Button {
            player.playStation(at: index)
            if let radioName = radio.name {
                analytics.sendSignal(signal: "play", parameters: ["radio.name":radioName])
            }
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

    private var shazamButton: some View {
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

    @ViewBuilder
    private func shazamStatusFooter(message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "shazam.logo.fill")
                .font(.system(size: 11, weight: .semibold))
            Text(message)
                .font(.footnote)
            Spacer()
            Button {
                shazam.resetStatus()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.white.opacity(0.75))
        .padding(.horizontal, 4)
        .padding(.top, 6)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

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
            artworkFallback
        }
    }

    private var artworkFallback: some View {
        Circle()
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

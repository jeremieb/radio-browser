#if os(macOS)
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit

// MARK: - Animated blob background (Apple Music–style)

private struct BlobConfig {
    let phaseX: Double
    let phaseY: Double
    let speedX: Double
    let speedY: Double
    let relativeSize: CGFloat   // fraction of the view's shorter dimension
    let colorIndex: Int         // which palette color to use
}

private let blobConfigs: [BlobConfig] = [
    BlobConfig(phaseX: 0.0,  phaseY: 0.0,  speedX: 0.37, speedY: 0.29, relativeSize: 0.85, colorIndex: 0),
    BlobConfig(phaseX: 1.2,  phaseY: 2.1,  speedX: 0.23, speedY: 0.41, relativeSize: 0.75, colorIndex: 1),
    BlobConfig(phaseX: 3.5,  phaseY: 0.7,  speedX: 0.51, speedY: 0.19, relativeSize: 0.70, colorIndex: 2),
    BlobConfig(phaseX: 0.9,  phaseY: 3.3,  speedX: 0.17, speedY: 0.53, relativeSize: 0.65, colorIndex: 3),
    BlobConfig(phaseX: 2.3,  phaseY: 1.5,  speedX: 0.43, speedY: 0.31, relativeSize: 0.60, colorIndex: 0),
]

private struct AnimatedBlobBackground: View {
    let palette: [Color]
    let time: Double            // seconds since some epoch, drives the animation

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Dark base so blobs have something to glow against
                Color.black.opacity(0.55)

                ForEach(blobConfigs.indices, id: \.self) { i in
                    let cfg = blobConfigs[i]
                    let color = palette.isEmpty ? Color.blue : palette[cfg.colorIndex % palette.count]
                    let diameter = min(w, h) * cfg.relativeSize

                    // Lissajous-like drift: keeps blobs within the view bounds
                    let cx = w * 0.5 + (w * 0.38) * sin(time * cfg.speedX + cfg.phaseX)
                    let cy = h * 0.5 + (h * 0.38) * cos(time * cfg.speedY + cfg.phaseY)

                    Ellipse()
                        .fill(color.opacity(0.82))
                        .frame(width: diameter, height: diameter * 0.8)
                        .position(x: cx, y: cy)
                }
            }
            .blur(radius: 72)          // the heavy blur is what makes it look like Apple Music
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

struct RadioMenuBarView: View {
    
    @StateObject private var player = RadioPlayerViewModel()
    @State private var coverTint: Color = Color(red: 0.42, green: 0.58, blue: 0.86)
    @State private var blobPalette: [Color] = [
        Color(red: 0.42, green: 0.58, blue: 0.86),
        Color(red: 0.25, green: 0.42, blue: 0.78),
        Color(red: 0.55, green: 0.32, blue: 0.82),
        Color(red: 0.30, green: 0.60, blue: 0.90),
    ]
    @Environment(ShazamService.self) private var shazam
    @Environment(\.openWindow) private var openWindow
    @State private var shazamPulse = false
    @State private var vinylRotation: Double = 0
    @State private var vinylAnimationTask: Task<Void, Never>?
    @State private var isVisible = false
    private let animationStartDate = Date()
    
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
        .onAppear { isVisible = true }
        .onDisappear { isVisible = false }
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
            // Static material base — visible when not playing
            Color.clear.background(.ultraThinMaterial)

            if isExpandedPlayer {
                TimelineView(.animation(paused: !player.isPlaying || !isVisible)) { context in
                    let elapsed = context.date.timeIntervalSince(animationStartDate)
                    AnimatedBlobBackground(palette: blobPalette, time: elapsed)
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: 460, maxHeight: 460)
        .animation(.easeInOut(duration: 0.8), value: isExpandedPlayer)
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
            let defaultPalette: [Color] = [
                Color(red: 0.42, green: 0.58, blue: 0.86),
                Color(red: 0.25, green: 0.42, blue: 0.78),
                Color(red: 0.55, green: 0.32, blue: 0.82),
                Color(red: 0.30, green: 0.60, blue: 0.90),
            ]
            await MainActor.run {
                coverTint = defaultPalette[0]
                blobPalette = defaultPalette
            }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: artworkURL)
            guard let image = NSImage(data: data) else { return }

            let palette = image.quadrantPalette
            await MainActor.run {
                if let first = palette.first.map({ Color(nsColor: $0) }) {
                    coverTint = first
                }
                blobPalette = palette.map { Color(nsColor: $0) }
            }
        } catch {
            // Keep the existing palette when color extraction fails.
        }
    }
}

private extension NSImage {
    var averageColor: NSColor? {
        quadrantPalette.first
    }

    /// Returns the average color of each image quadrant (TL, TR, BL, BR),
    /// giving a natural 4-color palette that reflects the artwork's actual hues.
    var quadrantPalette: [NSColor] {
        guard let tiffData = tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else {
            return []
        }

        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let full = ciImage.extent
        let hw = full.width / 2
        let hh = full.height / 2

        let quadrants: [CGRect] = [
            CGRect(x: full.minX,      y: full.minY + hh, width: hw, height: hh), // top-left
            CGRect(x: full.minX + hw, y: full.minY + hh, width: hw, height: hh), // top-right
            CGRect(x: full.minX,      y: full.minY,       width: hw, height: hh), // bottom-left
            CGRect(x: full.minX + hw, y: full.minY,       width: hw, height: hh), // bottom-right
        ]

        return quadrants.compactMap { rect -> NSColor? in
            let filter = CIFilter.areaAverage()
            filter.inputImage = ciImage
            filter.extent = rect
            guard let output = filter.outputImage else { return nil }

            var pixel = [UInt8](repeating: 0, count: 4)
            context.render(
                output,
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
}

#Preview {
    RadioMenuBarView()
}
#endif

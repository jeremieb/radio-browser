#if os(macOS)
import SwiftUI
import CoreImage
import AppKit

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
                MenuBarHeaderView()

                StationStripView(player: player, analytics: analytics)

                if isExpandedPlayer {
                    NowPlayingView(
                        player: player,
                        vinylRotation: vinylRotation,
                        shazamPulse: shazamPulse,
                        analytics: analytics
                    )
                }

                if let message = shazam.statusMessage {
                    ShazamStatusFooterView(message: message)
                }
            }
            .frame(maxWidth: 460, maxHeight: 460, alignment: .topLeading)
            .padding(.vertical)
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
                NSApp.activate(ignoringOtherApps: true)
            default:
                withAnimation(.default) { shazamPulse = false }
            }
        }
    }

    // MARK: - Background

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

    // MARK: - Palette extraction

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

#Preview {
    RadioMenuBarView()
}
#endif

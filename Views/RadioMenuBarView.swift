#if os(macOS)
import SwiftUI

struct RadioMenuBarView: View {

    @StateObject private var player = RadioPlayerViewModel()
    @Environment(ShazamService.self) private var shazam
    @Environment(\.openWindow) private var openWindow
    @Environment(\.analytics) private var analytics
    @State private var shazamPulse = false
    @State private var isVisible = false
    private let animationStartDate = Date()

    private var isExpandedPlayer: Bool {
        player.isPlaying || player.nowPlayingArtworkURL != nil
    }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(alignment: .leading) {
                MenuBarHeaderView()

                StationStripView(player: player)

                if isExpandedPlayer {
                    NowPlayingView(
                        player: player,
                        shazamPulse: shazamPulse
                    )
                }

                if let message = shazam.statusMessage {
                    ShazamStatusFooterView(message: message)
                }
            }
            .frame(minWidth: 340, minHeight: 340, alignment: .topLeading)
            .frame(maxWidth: 460, maxHeight: 460, alignment: .topLeading)
            .padding(.vertical)
        }
        .onAppear {
            isVisible = true
            RadioPlaybackCoordinator.shared.activePlayer = player
        }
        .onDisappear { isVisible = false }
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
                    AnimatedBlobBackground(palette: player.blobPalette, time: elapsed)
                }
                .transition(.opacity)
            }
        }
        .frame(maxWidth: 460, maxHeight: 460)
        .animation(.easeInOut(duration: 0.8), value: isExpandedPlayer)
    }
}

#Preview {
    RadioMenuBarView()
}
#endif

#if os(iOS)
import SwiftUI

struct ContentView: View {
    @StateObject private var player = RadioPlayerViewModel()
    @State private var blobPalette: [Color] = [
        Color(red: 0.42, green: 0.58, blue: 0.86),
        Color(red: 0.25, green: 0.42, blue: 0.78),
        Color(red: 0.55, green: 0.32, blue: 0.82),
        Color(red: 0.30, green: 0.60, blue: 0.90),
    ]
    @Environment(ShazamService.self) private var shazam
    @State private var shazamPulse = false
    @State private var vinylRotation: Double = 0
    @State private var vinylAnimationTask: Task<Void, Never>?
    @State private var shazamResultSheet = false
    private let animationStartDate = Date()
    private let analytics = Analytics.shared

    var body: some View {
        ZStack {
            // Animated blob background
            TimelineView(.animation(paused: !player.isPlaying)) { context in
                let elapsed = context.date.timeIntervalSince(animationStartDate)
                AnimatedBlobBackground(palette: blobPalette, time: elapsed)
            }
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Radio Browser")
                    .font(.title).fontWeight(.bold).fontWidth(.expanded)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Station strip
                StationStripView(player: player, analytics: analytics)

                // Now playing
                if player.isPlaying || player.nowPlayingArtworkURL != nil {
                    NowPlayingView(
                        player: player,
                        vinylRotation: vinylRotation,
                        shazamPulse: shazamPulse,
                        analytics: analytics
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer(minLength: 0)

                // Shazam status banner
                if let message = shazam.statusMessage {
                    ShazamStatusFooterView(message: message)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $shazamResultSheet) {
            if case .matched(let result) = shazam.state {
                #if os(macOS)
                    ShazamResultView(result: result)
                        .presentationDetents([.medium])
                #else
                    ShazamResultView(result: result)
                        .presentationDetents([.fraction(0.70)])
                #endif
            }
        }
        .task(id: player.nowPlayingArtworkURL) {
            await refreshBlobPalette()
        }
        .onChange(of: player.isPlaying) { _, isPlaying in
            vinylAnimationTask?.cancel()
            if isPlaying {
                vinylAnimationTask = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 16_000_000)
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
                shazamResultSheet = true
            default:
                withAnimation(.default) { shazamPulse = false }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: player.isPlaying)
    }

    private func refreshBlobPalette() async {
        guard let artworkURL = player.nowPlayingArtworkURL else {
            await MainActor.run {
                blobPalette = [
                    Color(red: 0.42, green: 0.58, blue: 0.86),
                    Color(red: 0.25, green: 0.42, blue: 0.78),
                    Color(red: 0.55, green: 0.32, blue: 0.82),
                    Color(red: 0.30, green: 0.60, blue: 0.90),
                ]
            }
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: artworkURL)
            guard let image = UIImage(data: data) else { return }
            let palette = image.quadrantPalette
            await MainActor.run {
                blobPalette = palette.map { Color(uiColor: $0) }
            }
        } catch {}
    }
}

#Preview {
    ContentView()
        .environment(ShazamService())
}
#endif

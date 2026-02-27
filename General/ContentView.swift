#if !os(macOS)
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
    @State private var showNowPlaying = false
    @State private var hideNowPlayingTask: Task<Void, Never>?
    private let animationStartDate = Date()
    private let analytics = Analytics.shared

    var body: some View {
        ZStack {
            
            // Animated blob background
            TimelineView(.animation(paused: !player.isPlaying)) { context in
                let elapsed = context.date.timeIntervalSince(animationStartDate)
                AnimatedBlobBackground(palette: blobPalette, time: elapsed)
            }.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                #if os(iOS)
                // Header
                Text("Broadcast Alternative Collective")
                    .font(.title).fontWeight(.bold).fontWidth(.expanded)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                #endif

                // Station browser
                #if os(tvOS)
                TVOSStationBrowserView(player: player, analytics: analytics)
                #else
                CoverFlowStationView(player: player, analytics: analytics)
                #endif

                // Now playing
                if showNowPlaying {
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
                hideNowPlayingTask?.cancel()
                showNowPlaying = true
                vinylAnimationTask = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(nanoseconds: 16_000_000)
                        vinylRotation += 0.6
                    }
                }
            } else {
                hideNowPlayingTask?.cancel()
                hideNowPlayingTask = Task {
                    try? await Task.sleep(for: .seconds(2))
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showNowPlaying = false
                    }
                }
            }
        }
        .onChange(of: player.nowPlayingArtworkURL) { _, artworkURL in
            if artworkURL != nil {
                hideNowPlayingTask?.cancel()
                showNowPlaying = true
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

#if os(tvOS)
private struct TVOSStationBrowserView: View {
    @ObservedObject var player: RadioPlayerViewModel
    let analytics: Analytics

    private let idleCardSize: CGFloat = 350
    private let playingCardSize: CGFloat = 220
    private let spacing: CGFloat = 46

    @State private var scrolledID: Int?
    @FocusState private var focusedStationIndex: Int?

    private var cardSize: CGFloat {
        player.isPlaying ? playingCardSize : idleCardSize
    }

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(Array(MyRadios.enumerated()), id: \.offset) { index, radio in
                            Button {
                                player.playStation(at: index)
                                if let radioName = radio.name {
                                    analytics.sendSignal(signal: "play", parameters: ["radio.name": radioName])
                                }
                            } label: {
                                cardContent(for: radio, isSelected: player.selectedStationIndex == index)
                                    .frame(width: cardSize, height: cardSize)
                                    .scaleEffect(focusedStationIndex == index ? 1.06 : 1.0)
                                    .animation(.spring(response: 0.32, dampingFraction: 0.78), value: focusedStationIndex)
                            }
                            .buttonStyle(.plain)
                            .focusEffectDisabled()
                            .focused($focusedStationIndex, equals: index)
                            .disabled(radio.disable ?? false)
                            .id(index)
                        }
                    }
                    .padding(.horizontal, max(0, (geo.size.width - cardSize) / 2))
                    .padding(.vertical, player.isPlaying ? 16 : 40)
                }
                .onAppear {
                    let index = player.selectedStationIndex
                    scrolledID = index
                    focusedStationIndex = index
                    scrollTo(index, proxy: proxy, animated: false)
                }
                .onChange(of: focusedStationIndex) { _, newFocused in
                    guard let index = newFocused else { return }
                    scrolledID = index
                    scrollTo(index, proxy: proxy, animated: true)

                    if !player.isPlaying, player.selectedStationIndex != index {
                        player.selectedStationIndex = index
                    }
                }
                .onChange(of: player.selectedStationIndex) { _, newIndex in
                    scrolledID = newIndex
                    focusedStationIndex = newIndex
                    scrollTo(newIndex, proxy: proxy, animated: true)
                }
                .onChange(of: player.isPlaying) { _, _ in
                    let index = player.selectedStationIndex
                    scrolledID = index
                    focusedStationIndex = index
                    scrollTo(index, proxy: proxy, animated: true)
                }
            }
        }
        .padding(.vertical, 48)
        .frame(maxHeight: player.isPlaying ? cardSize + 160 : .infinity)
    }

    private func scrollTo(_ index: Int, proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                proxy.scrollTo(index, anchor: .center)
            }
        } else {
            proxy.scrollTo(index, anchor: .center)
        }
    }

    @ViewBuilder
    private func cardContent(for radio: Radio, isSelected: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let imageName = radio.image, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: cardSize, height: cardSize)
                    .clipped()
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.32, green: 0.39, blue: 0.72),
                                Color(red: 0.20, green: 0.25, blue: 0.55),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(radio.name ?? "")
                .font(.footnote).fontWeight(.semibold).fontWidth(.expanded)
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

            if isSelected {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(radio.disable ?? false ? 0.4 : 1)
    }
}
#endif
#endif

#if !os(macOS)
import SwiftUI

struct ContentView: View {
    @StateObject private var player = RadioPlayerViewModel()
    @Environment(ShazamService.self) private var shazam
    @Environment(\.analytics) private var analytics
    @State private var shazamPulse = false
    @State private var shazamResultSheet = false
    private let animationStartDate = Date()

    var body: some View {
        ZStack {

            // Animated blob background
            TimelineView(.animation(paused: !player.isPlaying)) { context in
                let elapsed = context.date.timeIntervalSince(animationStartDate)
                AnimatedBlobBackground(palette: player.blobPalette, time: elapsed)
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
                TVOSStationBrowserView(player: player)
                #else
                CoverFlowStationView(player: player)
                #endif

                // Now playing
                if player.showNowPlaying {
                    NowPlayingView(
                        player: player,
                        shazamPulse: shazamPulse
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeInOut(duration: 0.5), value: player.showNowPlaying)
        }
        .sheet(isPresented: $shazamResultSheet) {
            if case .matched(let result) = shazam.state {
                ShazamResultView(result: result)
                    .presentationDetents([.fraction(0.70)])
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
}

#Preview {
    ContentView()
        .environment(ShazamService())
}

#if os(tvOS)
private struct TVOSStationBrowserView: View {
    @ObservedObject var player: RadioPlayerViewModel
    @Environment(\.analytics) private var analytics

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
                                    .animation(.spring(response: 0.32, dampingFraction: 0.78), value: focusedStationIndex)
                            }
                            .focused($focusedStationIndex, equals: index)
                            .disabled(radio.disable ?? false)
                            .id(index)
                        }
                    }
                    .padding(.horizontal, max(0, (geo.size.width - cardSize) / 2))
                    .padding(.vertical, 60)
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
        if let imageName = radio.image, !imageName.isEmpty {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    }
}
#endif
#endif

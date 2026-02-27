#if os(iOS)
import SwiftUI

struct CoverFlowStationView: View {
    @ObservedObject var player: RadioPlayerViewModel
    let analytics: Analytics

    private let baseCardSize: CGFloat = 220
    private let spacing: CGFloat = 12
    private let verticalPadding: CGFloat = 30

    private let maxRotation: Double = 55
    private let rotationFalloff: Double = 0.6

    private var cardSize: CGFloat { player.isPlaying ? baseCardSize * 0.8 : baseCardSize }

    // Drives both user-gesture snapping and programmatic scrolling.
    // scrollPosition(id:anchor:.center) ensures every settled position
    // is centred in the scroll view — no more leading-edge alignment.
    @State private var scrolledID: Int?
    @State private var snapBackTask: Task<Void, Never>? = nil

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(Array(MyRadios.enumerated()), id: \.offset) { index, radio in
                        cardView(for: radio, index: index, containerWidth: totalWidth)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, (totalWidth - cardSize) / 2)
                .padding(.vertical, verticalPadding)
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            // anchor: .center makes every snap (user or programmatic) land centred
            .scrollPosition(id: $scrolledID, anchor: .center)
            .coordinateSpace(name: "coverFlowContainer")
            .onAppear {
                // Delay so the scroll view is fully laid out before we jump
                let target = player.selectedStationIndex
                Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    scrolledID = target
                }
            }
            // When the playing station changes, immediately centre it
            .onChange(of: player.selectedStationIndex) { _, newIndex in
                snapBackTask?.cancel()
                snapBackTask = nil
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    scrolledID = newIndex
                }
            }
            // When the user scrolls away, start the 3-second snap-back timer
            .onChange(of: scrolledID) { _, newID in
                guard player.isPlaying, let id = newID,
                      id != player.selectedStationIndex else { return }
                scheduleSnapBack(to: player.selectedStationIndex)
            }
        }
        .frame(height: cardSize + verticalPadding * 2)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: player.isPlaying)
    }

    // MARK: - Snap-back

    private func scheduleSnapBack(to index: Int) {
        snapBackTask?.cancel()
        snapBackTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                    scrolledID = index
                }
            }
        }
    }

    // MARK: - Card views

    @ViewBuilder
    private func cardView(for radio: Radio, index: Int, containerWidth: CGFloat) -> some View {
        let isPlaying = player.selectedStationIndex == index
        let isFocused = scrolledID == index

        GeometryReader { geo in
            let cardMidX = geo.frame(in: .named("coverFlowContainer")).midX
            let containerMidX = containerWidth / 2
            let offset = cardMidX - containerMidX

            let normalizedOffset = offset / (cardSize + spacing)
            let clampedOffset = max(-2.0, min(2.0, normalizedOffset))

            let rotation = -clampedOffset * maxRotation * rotationFalloff
            let scale = 1.0 - abs(clampedOffset) * 0.10
            let verticalShift = abs(clampedOffset) * 14.0

            Button {
                if isFocused {
                    player.playStation(at: index)
                    if let radioName = radio.name {
                        analytics.sendSignal(signal: "play", parameters: ["radio.name": radioName])
                    }
                } else {
                    // Scroll this card to centre; schedule snap-back if something is playing
                    snapBackTask?.cancel()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        scrolledID = index
                    }
                    if player.isPlaying {
                        scheduleSnapBack(to: player.selectedStationIndex)
                    }
                }
            } label: {
                cardContent(for: radio, isPlaying: isPlaying, isFocused: isFocused)
                    .frame(width: cardSize, height: cardSize)
                    .scaleEffect(scale)
                    .rotation3DEffect(
                        .degrees(rotation),
                        axis: (x: 0, y: 1, z: 0),
                        anchor: clampedOffset > 0 ? .leading : .trailing,
                        perspective: 0.4
                    )
                    .offset(y: verticalShift)
                    .shadow(
                        color: .black.opacity(isPlaying ? 0.5 : 0.25),
                        radius: isPlaying ? 20 : 10,
                        x: 0,
                        y: isPlaying ? 8 : 4
                    )
            }
            .buttonStyle(.plain)
            .disabled(radio.disable ?? false)
            .frame(width: cardSize, height: cardSize)
            .animation(.interpolatingSpring(stiffness: 180, damping: 22), value: scrolledID)
        }
        .frame(width: cardSize, height: cardSize)
    }

    @ViewBuilder
    private func cardContent(for radio: Radio, isPlaying: Bool, isFocused: Bool) -> some View {
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
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(radio.name ?? "")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)

            if isPlaying {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.9), lineWidth: 1.5)
            } else if isFocused {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.4), lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(radio.disable ?? false ? 0.4 : 1)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CoverFlowStationView(
            player: RadioPlayerViewModel(),
            analytics: Analytics.shared
        )
    }
}
#endif

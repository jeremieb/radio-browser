import SwiftUI

struct StationStripView: View {
    @ObservedObject var player: RadioPlayerViewModel
    let analytics: Analytics

    private let cardSize: CGFloat = 58
    private let cardSpacing: CGFloat = 16
    private let peekAmount: CGFloat = 20

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cardSpacing) {
                ForEach(Array(MyRadios.enumerated()), id: \.offset) { index, radio in
                    stationCard(for: radio, index: index)
                        .frame(width: cardSize, height: cardSize)
                }
            }
            .scrollTargetLayout()
            .frame(minHeight: 80)
            .padding(.vertical, 2)
        }
        .safeAreaPadding(.leading, 16)
        .safeAreaPadding(.trailing, peekAmount)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func stationCard(for radio: Radio, index: Int) -> some View {
        let isSelected = player.selectedStationIndex == index

        Button {
            player.playStation(at: index)
            if let radioName = radio.name {
                analytics.sendSignal(signal: "play", parameters: ["radio.name": radioName])
            }
        } label: {
            stationThumbnail(for: radio)
                .frame(width: cardSize, height: cardSize)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1)
                )
                .opacity(radio.disable ?? false ? 0.4 : 1)
                .shadow(color: isSelected ? Color.black.opacity(0.8) : Color.clear, radius: 4)
                .scaleEffect(isSelected ? 1.1 : 1)
                .padding(4)
        }
        .buttonStyle(.plain)
        .disabled(radio.disable ?? false)
        .padding(8)
    }

    @ViewBuilder
    private func stationThumbnail(for radio: Radio) -> some View {
        if let imageName = radio.image, !imageName.isEmpty {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.32, green: 0.39, blue: 0.72))
        }
    }
}

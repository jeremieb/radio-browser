import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var player: RadioPlayerViewModel
    let vinylRotation: Double
    let shazamPulse: Bool
    let analytics: Analytics
    @Environment(ShazamService.self) private var shazam

    var body: some View {
        #if os(macOS)
        MacLayout
        #else
        PhoneLayout
        #endif
    }
    
    
    // MARK: iOS Layout
    
    @ViewBuilder
    private var PhoneLayout: some View {
        ZStack(alignment: .center) {
            vinylDisc
                .frame(width: 350, height: 350)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 14, y: 8)
                .rotationEffect(.degrees(vinylRotation))
            VStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading) {
                    Text(player.nowPlayingTitle)
                        .font(.body).fontWidth(.expanded).fontWeight(.bold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.65), radius: 8, x: 0, y: 3)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let subtitle = player.nowPlayingSubtitle {
                        Text(subtitle)
                            .font(.footnote).fontWeight(.medium)
                            .lineLimit(2)
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.65), radius: 8, x: 0, y: 3)
                    }
                }.padding(.top).frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                HStack(spacing: 22) {
                    Spacer()
                    ShazamButtonView(shazamPulse: shazamPulse, analytics: analytics)

                    Button {
                        player.togglePlayback()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                    }.buttonStyle(.plain)
                    Spacer()
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.horizontal)
    }
    
    // MARK: MacOS Layout
    
    @ViewBuilder
    private var MacLayout: some View {
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
                    ShazamButtonView(shazamPulse: shazamPulse, analytics: analytics)

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
        }
        .frame(maxWidth: 460, maxHeight: 460, alignment: .bottom)
        .padding(.horizontal)
    }

    // MARK: - Vinyl disc
    @ViewBuilder
    private var vinylDisc: some View {
        ZStack {
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
            #if os(macOS)
            Circle()
                .fill(Color.black)
                .stroke(Color.white, lineWidth: 1)
                .frame(width: 60, height: 60)
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
            #else
            Circle()
                .fill(Color.black)
                .stroke(Color.white, lineWidth: 1)
                .frame(width: 110, height: 110)
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
            #endif
        }
    }

    @ViewBuilder
    private var stationFallbackImage: some View {
        let radio = MyRadios.indices.contains(player.selectedStationIndex)
            ? MyRadios[player.selectedStationIndex] : nil
        if let imageName = radio?.image, !imageName.isEmpty {
            Image(imageName)
                .resizable()
                .scaledToFill()
        } else {
            Circle()
                .fill(Color.white.opacity(0.22))
                .overlay {
                    Image(systemName: "music.note")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
        }
    }
}

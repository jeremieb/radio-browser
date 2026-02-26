import SwiftUI

struct ShazamResultView: View {
    let result: ShazamResult
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Cover art
            AsyncImage(url: result.artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "music.note")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                @unknown default:
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 280, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.top, 24)

            // Track info
            VStack(spacing: 6) {
                Text(result.title)
                    .font(.title3).fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if let artist = result.artist {
                    Text(artist)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                if let album = result.album {
                    Text(album)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            // Apple Music button
            if let appleMusicURL = result.appleMusicURL {
                Button {
#if os(macOS)
                    NSWorkspace.shared.open(appleMusicURL)
#else
                    UIApplication.shared.open(appleMusicURL)
#endif
                } label: {
                    Label("Open in Apple Music", systemImage: "music.note")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.98, green: 0.22, blue: 0.39))
                .padding(.horizontal, 24)
            }

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        #if macOS
        .frame(width: 340)
        #else
        .padding()
        #endif
    }
}

#Preview {
    ShazamResultView(
        result: ShazamResult(
            title: "Midnight City",
            artist: "M83",
            album: "Hurry Up, We're Dreaming",
            artworkURL: nil,
            appleMusicURL: nil
        )
    )
}

import SwiftUI

struct ShazamStatusFooterView: View {
    let message: String
    @Environment(ShazamService.self) private var shazam

    var body: some View {
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
}

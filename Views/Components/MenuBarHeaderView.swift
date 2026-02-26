#if os(macOS)
import SwiftUI
import AppKit

struct MenuBarHeaderView: View {
    var body: some View {
        HStack {
            Text("Radio Browser")
                .font(.title).fontWeight(.bold).fontWidth(.expanded)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
                    .shadow(color: .white.opacity(0.35), radius: 3, y: -1)
            }
            .buttonStyle(.plain)
            .help("Quit Radio Browser")
        }.padding(.horizontal)
    }
}
#endif

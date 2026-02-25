//
//  Radio_BrowserApp.swift
//  Shared
//
//  Created by Jeremie Berduck on 08/04/2021.
//

import SwiftUI
import TelemetryDeck

@main
struct Radio_BrowserApp: App {
    
    
    init() {
        let config = TelemetryDeck.Config(appID: "A8A442EC-802E-4C4A-9702-67F46C7D6245")
        TelemetryDeck.initialize(config: config)
    }
    
#if os(macOS)
    @State private var shazam = ShazamService()
#endif

    var body: some Scene {
#if os(macOS)
        MenuBarExtra("Radio Browser", image: "my.radio.small") {
            RadioMenuBarView()
                .environment(shazam)
        }
        .menuBarExtraStyle(.window)

        Window("Shazam Result", id: "shazam-result") {
            ShazamResultWindowContent()
                .environment(shazam)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
#else
        WindowGroup {
            ContentView()
        }
#endif
    }
}

#if os(macOS)
/// Reads the matched result out of ShazamService and shows it, or closes if there is none.
private struct ShazamResultWindowContent: View {
    @Environment(ShazamService.self) private var shazam
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if case .matched(let result) = shazam.state {
            ShazamResultView(result: result)
        } else {
            // If opened before a match arrives (shouldn't normally happen),
            // show a brief placeholder and dismiss.
            ProgressView("Waiting for match…")
                .padding(40)
                .task {
                    // Poll until we have a result or the state reverts to idle.
                    while true {
                        try? await Task.sleep(nanoseconds: 200_000_000)
                        if case .matched = shazam.state { break }
                        if case .idle = shazam.state { dismiss(); break }
                    }
                }
        }
    }
}
#endif

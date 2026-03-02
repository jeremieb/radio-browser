import AppIntents

struct RadioShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PlayRadioStationIntent(),
            phrases: [
                "Play \(\.$station) on \(.applicationName)",
                "Listen to \(\.$station) on \(.applicationName)",
                "Start \(\.$station) on \(.applicationName)",
            ],
            shortTitle: "Play Station",
            systemImageName: "radio"
        )
    }
}

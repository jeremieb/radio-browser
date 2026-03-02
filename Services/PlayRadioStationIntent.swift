import AppIntents
#if os(macOS)
import AppKit
#endif

struct PlayRadioStationIntent: AppIntent {
    static var title: LocalizedStringResource = "Play Radio Station"
    static var description = IntentDescription("Plays a radio station in Radio Browser")
    static var supportedModes: IntentModes = .foreground(.immediate)

    @Parameter(title: "Station")
    var station: RadioStationAppEntity

    init() {}

    init(station: RadioStationAppEntity) {
        self.station = station
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        #if os(macOS)
        // On macOS the app is a MenuBarExtra agent. Activating it causes the menu bar
        // panel to appear, which initialises RadioMenuBarView and registers its player
        // with the coordinator. We then wait one run-loop turn for the view to appear.
        NSApp.activate(ignoringOtherApps: true)
        try? await Task.sleep(for: .milliseconds(150))
        #endif
        RadioPlaybackCoordinator.shared.requestPlay(stationID: station.id)
        return .result()
    }
}

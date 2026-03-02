import Foundation

/// Bridges App Intents (which run in the main app process) to the active RadioPlayerViewModel.
/// The player registers itself on init; the intent calls requestPlay(stationID:).
@MainActor
final class RadioPlaybackCoordinator {
    static let shared = RadioPlaybackCoordinator()

    weak var activePlayer: RadioPlayerViewModel?

    func requestPlay(stationID: String) {
        activePlayer?.playStation(byID: stationID)
    }

    private init() {}
}

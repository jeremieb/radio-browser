import Foundation
import ShazamKit
import AVFoundation

/// States the Shazam recognition flow can be in.
enum ShazamState: Equatable {
    case idle
    case listening
    case matched(ShazamResult)
    case noMatch
    case failed(String)

    static func == (lhs: ShazamState, rhs: ShazamState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.listening, .listening), (.noMatch, .noMatch):
            return true
        case (.matched(let a), .matched(let b)):
            return a.title == b.title && a.artist == b.artist
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

@MainActor
@Observable
final class ShazamService {
    private(set) var state: ShazamState = .idle

    private var session: SHManagedSession?
    private var matchTask: Task<Void, Never>?

    var isListening: Bool {
        if case .listening = state { return true }
        return false
    }

    /// Status message to show in the UI for non-match outcomes.
    var statusMessage: String? {
        switch state {
        case .noMatch:       return "No match found"
        case .failed(let e): return "Error: \(e)"
        default:             return nil
        }
    }

    /// Requests microphone permission if needed, then starts a Shazam session.
    /// Must be called from the main actor (button tap).
    func startListening() {
        cancel()
        state = .listening

        matchTask = Task {
            // Request mic permission before starting — this prompts the user
            // the first time and is a no-op on subsequent calls.
            let granted = await requestMicPermission()
            guard granted, !Task.isCancelled else {
                state = .failed(granted ? "Cancelled" : "Microphone access denied")
                return
            }

            let newSession = SHManagedSession()
            session = newSession

            let result = await newSession.result()

            guard !Task.isCancelled else { return }

            switch result {
            case .match(let match):
                if let item = match.mediaItems.first {
                    state = .matched(
                        ShazamResult(
                            title: item.title ?? "Unknown",
                            artist: item.artist,
                            album: item.subtitle,
                            artworkURL: item.artworkURL,
                            appleMusicURL: item.appleMusicURL
                        )
                    )
                } else {
                    state = .noMatch
                }
            case .noMatch:
                state = .noMatch
            case .error(let error, _):
                state = .failed(error.localizedDescription)
            }
        }
    }

    func cancel() {
        matchTask?.cancel()
        matchTask = nil
        session?.cancel()
        session = nil
        state = .idle
    }

    func resetStatus() {
        // Clear a noMatch / failed status back to idle so the footer disappears.
        if case .listening = state { return }
        state = .idle
    }

    // MARK: - Private

    private func requestMicPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

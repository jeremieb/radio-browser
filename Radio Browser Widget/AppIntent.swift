//
//  AppIntent.swift
//  Radio Browser Widget
//
//  Created by Jeremie Berduck on 25/2/26.
//

import AppIntents
import AppKit

struct OpenRadioBrowserIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Radio Browser"
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "radio-browser://open") else { return .result() }
        await MainActor.run {
            _ = NSWorkspace.shared.open(url)
        }
        return .result()
    }
}

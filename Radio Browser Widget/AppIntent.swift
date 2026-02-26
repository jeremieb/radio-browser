//
//  AppIntent.swift
//  Radio Browser Widget
//
//  Created by Jeremie Berduck on 25/2/26.
//

import AppIntents

struct OpenRadioBrowserIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Radio Browser"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

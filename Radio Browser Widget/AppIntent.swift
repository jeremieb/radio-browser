//
//  AppIntent.swift
//  Radio Browser Widget
//
//  Created by Jeremie Berduck on 25/2/26.
//

import AppIntents

struct RadioBrowserAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Radio Browser")
    static var defaultQuery = RadioBrowserEntityQuery()
    var id: String = "radio-browser"
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "Radio Browser") }
}

struct RadioBrowserEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [RadioBrowserAppEntity] {
        [RadioBrowserAppEntity()]
    }
}

struct OpenRadioBrowserIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Radio Browser"

    @Parameter(title: "Target")
    var target: RadioBrowserAppEntity

    init() {
        self.target = RadioBrowserAppEntity()
    }

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

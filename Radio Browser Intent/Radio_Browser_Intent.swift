//
//  Radio_Browser_Intent.swift
//  Radio Browser Intent
//
//  Created by Jeremie Berduck on 2/3/26.
//

import AppIntents

struct Radio_Browser_Intent: AppIntent {
    static var title: LocalizedStringResource { "Radio Browser Intent" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

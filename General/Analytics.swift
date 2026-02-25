//
//  Analytics.swift
//  Radio Browser
//
//  Created by Jeremie Berduck on 25/2/26.
//

import Foundation
import TelemetryDeck

class Analytics {
    
    static let shared = Analytics()
    
    func sendSignal(signal: String, parameters: [String: String]?) {
        if let parameters {
            TelemetryDeck.signal(
                signal,
                parameters: parameters
            )
        } else {
            TelemetryDeck.signal(signal)
        }
    }
}

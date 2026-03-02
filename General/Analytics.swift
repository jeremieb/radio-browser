//
//  Analytics.swift
//  Radio Browser
//
//  Created by Jeremie Berduck on 25/2/26.
//

import Foundation
import SwiftUI
import TelemetryDeck

// MARK: - Protocol

protocol AnalyticsProtocol {
    func sendSignal(signal: String, parameters: [String: String]?)
}

// MARK: - Concrete implementation

class Analytics: AnalyticsProtocol {

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

// MARK: - Environment

private struct AnalyticsEnvironmentKey: EnvironmentKey {
    static let defaultValue: any AnalyticsProtocol = Analytics.shared
}

extension EnvironmentValues {
    var analytics: any AnalyticsProtocol {
        get { self[AnalyticsEnvironmentKey.self] }
        set { self[AnalyticsEnvironmentKey.self] = newValue }
    }
}

//
//  Radio_Browser_Widget.swift
//  Radio Browser Widget
//
//  Created by Jeremie Berduck on 25/2/26.
//

import AppIntents
import WidgetKit
import SwiftUI

struct RadioBrowserControl: ControlWidget {
    static let kind: String = "com.jeremie.Radio-Browser.control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenRadioBrowserIntent()) {
                Label {
                    Text("Radio Browser")
                } icon: {
                    Image("my.radio.wave")
                }
            }
        }
        .displayName("Radio Browser")
        .description("Open Radio Browser.")
    }
}

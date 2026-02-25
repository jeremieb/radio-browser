//
//  Radio_BrowserApp.swift
//  Shared
//
//  Created by Jeremie Berduck on 08/04/2021.
//

import SwiftUI

@main
struct Radio_BrowserApp: App {
    var body: some Scene {
#if os(macOS)
        MenuBarExtra("Radio Browser", image: "my.radio") {
            RadioMenuBarView()
        }
        .menuBarExtraStyle(.window)
#else
        WindowGroup {
            ContentView()
        }
#endif
    }
}

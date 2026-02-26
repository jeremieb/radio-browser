//
//  ShazamButtonView.swift
//  Radio Browser
//
//  Created by Jeremie Berduck on 26/2/26.
//

import SwiftUI

struct ShazamButtonView: View {
    let shazamPulse: Bool
    let analytics: Analytics
    @Environment(ShazamService.self) private var shazam

    var body: some View {
        Button {
            if shazam.isListening {
                shazam.cancel()
            } else {
                shazam.startListening()
            }
            analytics.sendSignal(signal: "shazam", parameters: nil)
        } label: {
            Image(systemName: "shazam.logo.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(shazam.isListening ? Color.cyan : Color.white)
                .frame(width: 44, height: 44)
                .scaleEffect(shazamPulse ? 1.18 : 1.0)
                .shadow(color: shazam.isListening ? Color.cyan.opacity(0.6) : Color.black.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

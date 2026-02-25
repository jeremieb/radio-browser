# Radio Browser — Agent Reference

## What is this?

Radio Browser is a **macOS menu bar app** for streaming internet radio stations. It lives in the system menu bar and lets the user play curated stations (NTS 1, NTS 2, Worldwide FM) with live now-playing metadata, album artwork, AirPlay routing, and macOS Control Center / Lock Screen integration.

The iOS target exists as a shell (`ContentView` with a placeholder) but is not the primary focus.

---

## Project Structure

```
Radio Browser/
├── General/                        # App entry point & shared config
│   ├── Radio_BrowserApp.swift      # @main — MenuBarExtra (macOS) / WindowGroup (iOS)
│   ├── ContentView.swift           # iOS placeholder view
│   └── Info.plist

├── Models/                         # Pure data types, no logic
│   ├── Radio.swift                 # Radio struct + MyRadios catalogue (the station list)
│   └── NowPlayingModels.swift      # NowPlayingSnapshot + NTS & Worldwide FM API response types

├── View Models/                    # ObservableObject classes, no SwiftUI views
│   ├── RadioPlayerViewModel.swift  # Playback state, AVPlayer, bridges NowPlayingViewModel ↔ SystemNowPlayingCenter
│   └── NowPlayingViewModel.swift   # Polls station APIs every 30 s, publishes NowPlayingSnapshot via onUpdate callback

├── Views/                          # SwiftUI views only
│   ├── RadioMenuBarView.swift      # Root macOS menu bar UI (owns RadioPlayerViewModel)
│   └── Components/
│       └── AirPlayRoutePickerView.swift  # NSViewRepresentable wrapper for AVRoutePickerView

└── Services/                       # System-level integrations
    └── SystemNowPlayingCenter.swift # MPNowPlayingInfoCenter + MPRemoteCommandCenter (Control Center, Lock Screen, hardware keys)
```

---

## Data Flow

```
Radio_BrowserApp
    └─▶ RadioMenuBarView            (SwiftUI view, macOS only)
            │  @StateObject
            └─▶ RadioPlayerViewModel
                    ├─▶ AVPlayer                    (audio stream)
                    ├─▶ NowPlayingViewModel          (API polling → NowPlayingSnapshot via onUpdate)
                    └─▶ SystemNowPlayingCenter       (system media info + remote commands)
```

---

## Key Types

| Type | File | Role |
|---|---|---|
| `Radio` | Models/Radio.swift | Station definition (name, stream URL, now-playing API URL, image asset name) |
| `MyRadios` | Models/Radio.swift | Global catalogue of available stations |
| `NowPlayingSnapshot` | Models/NowPlayingModels.swift | Value type passed from `NowPlayingViewModel` to `RadioPlayerViewModel` |
| `NTSNowPlayingResponse` | Models/NowPlayingModels.swift | Decoded from NTS `/api/v2/live` |
| `WorldwideNowPlayingResponse` | Models/NowPlayingModels.swift | Decoded from Worldwide FM `/schedule/live` |
| `RadioPlayerViewModel` | View Models/RadioPlayerViewModel.swift | Playback control, published state consumed by `RadioMenuBarView` |
| `NowPlayingViewModel` | View Models/NowPlayingViewModel.swift | API polling loop, decodes NTS and Worldwide FM responses |
| `RadioMenuBarView` | Views/RadioMenuBarView.swift | Full menu bar UI: header, station strip, expanded player, background gradient |
| `AirPlayRoutePickerView` | Views/Components/AirPlayRoutePickerView.swift | Wraps `AVRoutePickerView` for AirPlay output selection |
| `SystemNowPlayingCenter` | Services/SystemNowPlayingCenter.swift | Updates macOS/iOS system now-playing info and handles remote play/pause/stop commands |

---

## Adding a New Station

1. Add an image asset to `Radio Browser/General/Assets.xcassets`.
2. Append a `Radio(...)` entry to `MyRadios` in `Models/Radio.swift`.
3. If the station uses a new API format, add the response types to `Models/NowPlayingModels.swift` and add a decoder branch in `NowPlayingViewModel.refresh(for:)`.

---

## Tech Stack

- **SwiftUI** — UI
- **AVFoundation / AVKit** — audio streaming + AirPlay picker
- **MediaPlayer** — system now-playing info, remote command center
- **CoreImage** — dominant color extraction from artwork (used for dynamic gradient tint)
- **URLSession** + **JSONDecoder** — API calls, no third-party networking libraries

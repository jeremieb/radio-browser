# Folder Structure — Mixed (SwiftUI + UIKit)

Use when incrementally migrating a UIKit app to SwiftUI, or when certain features require UIKit (e.g. camera, maps, complex custom controls).

```
MyApp/
├── App/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
│
├── Features/
│   ├── Home/                       # SwiftUI feature
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   ├── Dashboard/                  # UIKit feature (legacy or not yet migrated)
│   │   ├── DashboardViewController.swift
│   │   ├── DashboardViewModel.swift
│   │   └── DashboardCoordinator.swift
│   └── Camera/                     # UIKit-only (no SwiftUI equivalent)
│       ├── CameraViewController.swift
│       └── CameraViewModel.swift
│
├── Bridge/                         # Interop wrappers — isolate here, not in Features
│   ├── HomeHostingController.swift         # UIHostingController subclass
│   ├── LegacyPickerRepresentable.swift     # UIViewRepresentable
│   └── CameraViewControllerRepresentable.swift
│
├── Services/
│   ├── Networking/
│   ├── Auth/
│   └── Storage/
│
├── Core/
│   ├── Extensions/
│   ├── Components/                 # Both SwiftUI views and UIView subclasses
│   │   ├── SwiftUI/
│   │   │   └── PrimaryButton.swift
│   │   └── UIKit/
│   │       └── LegacyPrimaryButton.swift
│   ├── Utilities/
│   └── Models/
│
├── Resources/
└── tasks/
```

## Key Rules for Mixed Projects

- `Bridge/` is the only place for `UIHostingController` subclasses and `UIViewRepresentable` wrappers — never inside `Features/`
- Each feature is either SwiftUI or UIKit — do not mix both inside the same feature folder
- New features default to SwiftUI unless there is a clear technical reason for UIKit
- ViewModels are framework-agnostic (`import Foundation` only) — they work for both

## Test Targets

```
MyAppTests/
├── Features/
├── Services/
└── Mocks/

MyAppUITests/
└── Flows/
```

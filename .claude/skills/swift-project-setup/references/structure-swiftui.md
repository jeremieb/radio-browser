# Folder Structure — SwiftUI App

```
MyApp/
├── App/
│   ├── MyAppApp.swift              # @main entry point
│   └── ContentView.swift           # Root view — keep thin, delegates to features
│
├── Features/                       # One folder per user-facing feature
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── HomeModel.swift         # Feature-specific model (only if needed)
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── ProfileViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
│
├── Services/
│   ├── Networking/
│   │   ├── APIClient.swift
│   │   ├── Endpoint.swift
│   │   └── HTTPClientProtocol.swift
│   ├── Auth/
│   │   ├── AuthService.swift
│   │   └── AuthServiceProtocol.swift
│   └── Storage/
│       ├── UserDefaultsService.swift
│       └── PersistenceController.swift
│
├── Core/
│   ├── Extensions/
│   │   ├── String+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   └── View+Extensions.swift
│   ├── Components/                 # Reusable SwiftUI views (design system)
│   │   ├── PrimaryButton.swift
│   │   ├── LoadingView.swift
│   │   └── ErrorView.swift
│   ├── Utilities/
│   │   ├── PriceFormatter.swift
│   │   └── DateFormatter+Shared.swift
│   └── Models/                     # Shared domain models
│       ├── User.swift
│       └── APIError.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.xcstrings
│   └── Info.plist
│
└── tasks/
    ├── todo.md
    └── lessons.md
```

## Test Targets

```
MyAppTests/
├── Features/
│   ├── HomeViewModelTests.swift
│   └── ProfileViewModelTests.swift
├── Services/
│   └── AuthServiceTests.swift
└── Mocks/
    ├── MockAuthService.swift
    └── MockHTTPClient.swift

MyAppUITests/
└── Flows/
    ├── LoginFlowTests.swift
    └── OnboardingFlowTests.swift
```

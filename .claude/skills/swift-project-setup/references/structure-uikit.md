# Folder Structure — UIKit App

```
MyApp/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── AppCoordinator.swift        # Root coordinator — owns navigation
│
├── Features/                       # One folder per user-facing feature
│   ├── Home/
│   │   ├── HomeViewController.swift
│   │   ├── HomeViewModel.swift
│   │   ├── HomeCoordinator.swift   # Navigation for this feature
│   │   └── Views/                  # UIView subclasses for this feature only
│   │       └── HomeHeaderView.swift
│   └── Profile/
│       ├── ProfileViewController.swift
│       ├── ProfileViewModel.swift
│       └── ProfileCoordinator.swift
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
│       └── UserDefaultsService.swift
│
├── Core/
│   ├── Extensions/
│   │   ├── UIViewController+Extensions.swift
│   │   ├── UIView+Extensions.swift
│   │   └── String+Extensions.swift
│   ├── Components/                 # Reusable UIView subclasses
│   │   ├── PrimaryButton.swift
│   │   └── LoadingView.swift
│   ├── Utilities/
│   │   └── PriceFormatter.swift
│   └── Models/
│       ├── User.swift
│       └── APIError.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.xcstrings
│   ├── Main.storyboard             # Only if using storyboards
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

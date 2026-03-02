# SPM Package.swift Skeleton

Use when extracting a feature or shared module into a local or distributed Swift Package.

## Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyFeatureKit",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MyFeatureKit",
            targets: ["MyFeatureKit"]
        )
    ],
    dependencies: [
        // .package(url: "https://github.com/...", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyFeatureKit",
            dependencies: [],
            path: "Sources/MyFeatureKit"
        ),
        .testTarget(
            name: "MyFeatureKitTests",
            dependencies: ["MyFeatureKit"],
            path: "Tests/MyFeatureKitTests"
        )
    ]
)
```

## Folder Structure

```
MyFeatureKit/
├── Package.swift
├── Sources/
│   └── MyFeatureKit/
│       ├── MyFeatureKit.swift      # Public API — explicit public declarations only
│       └── Internal/               # Internal implementation details
│           └── HelperType.swift
└── Tests/
    └── MyFeatureKitTests/
        └── MyFeatureKitTests.swift
```

## Rules

- Mark only what consumers need as `public` — default to `internal`
- No `UIKit` or `SwiftUI` imports in business logic targets — keep them platform-agnostic when possible
- Add a separate target for UI components if needed (e.g. `MyFeatureKitUI`)
- Use `// swift-tools-version: 5.9` minimum for `@Observable` and macros support

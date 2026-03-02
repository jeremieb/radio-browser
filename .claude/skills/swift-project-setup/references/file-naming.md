# File Naming & Group Conventions

## File Naming

### Good

```
UserProfileView.swift           # type name matches file name exactly
UserProfileViewModel.swift      # one primary type per file
AuthServiceProtocol.swift       # protocol in its own file when non-trivial
String+Validation.swift         # extension: Type+Purpose
DateFormatter+Shared.swift      # extension: Type+Purpose
MockAuthService.swift           # mock: Mock + protocol name (without "Protocol")
HomeViewModelTests.swift        # tests: TypeName + Tests
```

### Bad

```
Helpers.swift                   # vague — becomes a dumping ground
Utils.swift                     # same problem
Extensions.swift                # too broad
NewFile.swift                   # Xcode default, never keep it
Manager.swift                   # what does it manage?
VC.swift                        # abbreviation
homeview.swift                  # not UpperCamelCase
UserProfile+ViewModel.swift     # + is for extensions, not VM pairing
```

---

## Xcode Group Naming

```
Features/       # plural noun, title case
Services/       # plural noun
Core/           # singular (it's a single layer, not a collection)
Resources/      # plural noun
Tests/          # plural — not "Test"
Mocks/          # plural — not "Mock"
Extensions/     # plural noun
Components/     # plural noun
Views/          # only inside a UIKit feature — never as a top-level group
```

Rules:
- Title case, no spaces, no abbreviations
- Plural for collections (`Features/`, `Models/`, `Mocks/`)
- Name reflects contents exactly — no surprises
- Never create `Misc/`, `Other/`, or `Temp/`

---

## What Never Goes Where

| Code | Wrong location | Right location |
|---|---|---|
| Network calls | `View`, `ViewController` | `Services/Networking/` |
| `UserDefaults` access | `View`, `ViewModel` | `Services/Storage/` |
| Business logic | `View`, `ViewController` | `ViewModel`, `Service` |
| Navigation / routing | `ViewModel` | `Coordinator` (UIKit) or parent `View` (SwiftUI) |
| Reusable UI components | Inside a `Feature/` | `Core/Components/` |
| Shared domain models | `Services/Networking/` | `Core/Models/` |
| Test mocks | Main app target | Test target `Mocks/` |
| `UIHostingController` wrappers | `Features/` | `Bridge/` (mixed projects only) |
| `ModelContext` / `NSManagedObjectContext` | `ViewModel`, `View` | `Services/Storage/` (repository only) |
| Persistence models (`@Model`, `NSManagedObject`) | `Services/` | `Core/Models/` |

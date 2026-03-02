# ENTERPRISE iOS TESTING STANDARD

Applies to: Swift, UIKit, SwiftUI projects

All test code MUST align with Apple XCTest / Swift Testing documentation and Xcode Test Plan best practices.

---

# 1. FRAMEWORK POLICY

## 1.1 Approved Frameworks
- Swift Testing (preferred for new unit test suites)
- XCTest (required for UI tests, performance tests, legacy support)

Do NOT mix frameworks in the same test target.

## 1.2 Test Targets
Project MUST contain:
- Unit Test Target
- UI Test Target
- Performance tests (if business-critical logic exists)

---

# 2. UNIT TEST REQUIREMENTS

## 2.1 Structure
Each test MUST:
- Follow Arrange / Act / Assert
- Validate exactly one behavior
- Be deterministic

## 2.2 Determinism Policy
Tests MUST NOT:
- Hit real network
- Use system clock directly
- Depend on randomness
- Depend on persistent storage
- Depend on shared global state

All external dependencies MUST be injected via protocol abstractions.

## 2.3 Naming Convention
Format:
`test_when_<Condition>_should_<ExpectedOutcome>()`

Failure output must explain business intent.

## 2.4 Isolation
- Fresh instance per test.
- No shared mutable state.
- setUp/tearDown used only when necessary.

---

# 3. ARCHITECTURE FOR TESTABILITY (MANDATORY)

Projects MUST follow:
- Dependency Injection
- Protocol-oriented design
- Thin UI layer
- Business logic outside ViewControllers / Views

Business logic inside UIKit controllers or SwiftUI Views is forbidden.

---

# 4. ASYNC / CONCURRENCY POLICY

If using async/await:
- Tests MUST be async.
- No sleep().
- No polling loops.

If using callbacks:
- Use official expectation mechanisms only.

Async tests MUST be fully deterministic.

---

# 5. UIKIT TESTING RULES

## 5.1 Unit Tests
Test:
- ViewModels
- Coordinators
- Services
- Formatters
- State transformations

Avoid:
- Direct layout assertions
- Private property inspection

## 5.2 UI Tests (XCUITest)
UI tests MUST:
- Cover only critical business flows
- Use accessibility identifiers
- Avoid coordinate-based taps
- Avoid fragile view hierarchy queries

UI tests should represent <20% of total test count.

---

# 6. SWIFTUI TESTING RULES

## 6.1 Unit Focus
SwiftUI Views MUST remain declarative shells.

Test:
- Observable state
- ViewModels
- Reducers
- Business rules

Do NOT:
- Assert view tree structure
- Assert layout positions
- Snapshot test without approval

## 6.2 UI Tests
Required for:
- Navigation
- Critical flows
- Accessibility validation

---

# 7. PERFORMANCE TESTING

Required when:
- Algorithmic complexity matters
- Data transformations are large
- Business SLAs exist

Must use XCTest performance APIs.

---

# 8. TEST PLAN GOVERNANCE

Xcode Test Plans MUST define:
- Smoke suite
- Full regression suite
- CI configuration
- Environment matrix

All PRs MUST pass unit tests before merge.

---

# 9. CODE COVERAGE POLICY

Target: meaningful coverage, not numeric vanity.

Coverage below 70% requires justification.
Low coverage in critical modules is not allowed.

---

# 10. PROHIBITED PRACTICES

- Testing private methods
- Testing implementation details
- Using sleep() in tests
- Real API calls in unit tests
- Global singletons without injection
- Snapshot testing without review

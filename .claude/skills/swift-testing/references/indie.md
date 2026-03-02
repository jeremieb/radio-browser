# INDIE iOS TESTING GUIDELINES
For Swift, UIKit, SwiftUI projects.
Keep tests fast, useful, and sustainable.

---

# 1. FRAMEWORK

- Use Swift Testing for new logic tests.
- Use XCTest for UI tests.
- Keep it simple.

---

# 2. WHAT TO TEST

Always test:
- Business logic
- ViewModels
- Data transformations
- Formatting rules
- Edge cases

Rarely test:
- UI layout
- View hierarchy
- Visual details

Never test:
- Private implementation details

---

# 3. STRUCTURE

Each test:
- Arrange
- Act
- Assert
- One behavior only

Test names should clearly explain intent.

Example:
`test_whenUserIsPremium_shouldUnlockFeature`

---

# 4. KEEP TESTS DETERMINISTIC

No:
- Real network calls
- Real time dependency
- Random behavior

Inject dependencies so they can be mocked.

---

# 5. ASYNC

If using async/await:
- Write async tests.
- Do not use sleep().

Wait deterministically.

---

# 6. UIKIT RULE

Move logic out of ViewControllers.
Test the logic, not the controller.

UI tests:
- Only for main flows.
- Use accessibility identifiers.

---

# 7. SWIFTUI RULE

SwiftUI views should stay thin.

Test:
- State
- ViewModels
- Business rules

Do not test:
- Exact view structure
- Layout constraints

---

# 8. HOW MANY TESTS?

Prefer:
- Many small fast unit tests
- Very few UI tests

If tests feel heavy, architecture probably needs cleanup.

---

# 9. PERFORMANCE

Only measure performance when it matters.
Do not prematurely optimize.

---

# 10. PHILOSOPHY

Tests are safety nets.
Not bureaucracy.

Write tests that:
- Protect refactoring
- Prevent regressions
- Increase confidence

Avoid writing tests just to increase coverage.

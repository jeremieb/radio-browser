# .gitignore — Xcode / Swift

```gitignore
# Xcode build artifacts
build/
DerivedData/
*.pbxuser
*.mode1v3
*.mode2v3
*.perspectivev3
!default.pbxuser
!default.mode1v3
!default.mode2v3
!default.perspectivev3

# User-specific Xcode settings
*.xcuserstate
xcuserdata/
*.xcscmblueprint
*.xcodeproj/xcuserdata/
*.xcworkspace/xcuserdata/

# Swift Package Manager
.build/
.swiftpm/

# CocoaPods (if used)
Pods/

# Carthage (if used)
Carthage/Build/

# Fastlane
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# OS
.DS_Store
Thumbs.db

# Secrets — never commit
*.p12
*.mobileprovision
*.cer
GoogleService-Info.plist
```

## Notes

**`Package.resolved`**
- Apps: commit it — ensures reproducible builds across the team
- Libraries / SDKs: do not commit it — let consumers resolve their own versions

**CocoaPods**
- Commit `Podfile.lock`
- Add `Pods/` to `.gitignore` if you regenerate on CI
- Or commit `Pods/` if CI has no internet access (rare)

# Contributing to Food Journal App

Thanks for contributing. This project is a SwiftUI iOS app, so the best contributions are small, reviewable, and tied to a clear user-facing improvement or bug fix.

## Before You Start

- Check existing issues before opening a new one
- Use the bug report or feature request template when possible
- Keep pull requests focused on one change set
- Avoid mixing refactors with unrelated behavior changes

## Local Setup

1. Clone the repository.
2. Open `FoodJournalApp.xcodeproj` in Xcode 16 or newer.
3. Select the `FoodJournalApp` scheme.
4. Run the app on an iOS 16.0+ simulator.

## Development Guidelines

- Prefer small, readable SwiftUI views over large monolithic screens.
- Match the current architecture: models in `Models/`, persistence in `Storage/`, orchestration in `ViewModels/` and `Services/`.
- Keep user data private and local-first unless the project intentionally changes direction.
- Preserve the app's current behavior around optional location access and on-device OCR review.
- Add or update tests when behavior changes in a meaningful way.

## Testing

Run tests in Xcode or with:

```sh
destination_id="$(xcodebuild -project FoodJournalApp.xcodeproj -scheme FoodJournalApp -showdestinations 2>/dev/null | ruby -ne 'if $_ =~ /platform:iOS Simulator, id:([^,]+), OS:[^,]+, name:iPhone/; puts $1.strip; exit; end')"

xcodebuild clean test \
  -project FoodJournalApp.xcodeproj \
  -scheme FoodJournalApp \
  -destination "platform=iOS Simulator,id=${destination_id}" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

## Pull Request Expectations

- Describe what changed and why
- Include screenshots for UI changes when helpful
- Call out follow-up work or known limitations
- Confirm the project builds cleanly
- Confirm tests were run, or explain why they were not

## Commit Style

Clear, plain-English commit messages are enough. Examples:

- `Add README and GitHub community templates`
- `Fix menu scan duplicate item handling`
- `Improve journal filtering for drinks and products`

## Code of Conduct

By participating in this repository, you agree to follow the expectations in [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

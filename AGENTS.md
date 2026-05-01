# AGENTS.md

Codex should follow this file when working in this repository.

## Project Root

The real git/project root is:

```text
/Users/kim_kyun/Desktop/ForP/ForP
```

The parent directory `/Users/kim_kyun/Desktop/ForP` only contains wrapper/local Claude settings.

## Commands

```bash
# Generate or refresh the Tuist workspace
tuist generate

# Build the app
xcodebuild build \
  -workspace ForP.xcworkspace \
  -scheme ForP \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Run all tests
xcodebuild test \
  -workspace ForP.xcworkspace \
  -scheme ForP \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# TestFlight upload
bundle exec fastlane ios beta
```

`App/Secrets.xcconfig` and service configuration files must exist for real app builds.

## Stack

- iOS app
- SwiftUI
- TCA (The Composable Architecture)
- Tuist modular workspace
- Supabase
- Kakao SDK / Kakao Local API
- OpenAI API
- OpenWeather API
- SwiftData local cache
- fastlane for TestFlight

## Architecture

```text
App
  -> Features
      -> Domain
      -> CoreSharedUI
  -> Data
      -> Domain
      -> CoreNetwork
  -> Domain
CoreNetwork
CoreSharedUI
```

| Layer | Location | Role |
|---|---|---|
| App | `App/Sources/` | App entry, SDK setup, dependency wiring, SwiftData container |
| Features | `Modules/Features/Sources/` | SwiftUI views and TCA reducers |
| Domain | `Modules/Domain/Sources/` | Entities, repository protocols, ports, use cases |
| Data | `Modules/Data/Sources/` | Supabase, Kakao, OpenAI, weather, local cache implementations |
| CoreNetwork | `Modules/Core/Network/Sources/` | Shared network helpers |
| CoreSharedUI | `Modules/Core/SharedUI/Sources/` | Design tokens and shared UI |

## Codex Workflow

### Before editing

- Read the closest existing implementation first.
- For feature work, inspect the matching Feature, Domain, Data, and `App/Sources/ForPApp.swift` dependency wiring.
- Keep edits scoped to the user request.
- Do not refactor unrelated code.

### New feature flow

1. Domain entity/protocol/use case.
2. Data DTO/repository/service implementation.
3. Dependency registration in `App/Sources/ForPApp.swift`.
4. TCA reducer state/actions/effects.
5. SwiftUI view composition.
6. Parent navigation/delegate wiring.
7. Focused build or test verification.

### Small fix flow

- Read the target file.
- Patch only the behavior requested.
- Run the narrowest useful verification.

### Commit rule

- Do not commit automatically.
- Commit only when the user explicitly says `커밋해줘`, `/commit`, or equivalent.
- Commit messages must be Korean.
- Prefix commit title with `[feat]`, `[fix]`, `[refactor]`, `[docs]`, or `[test]`.
- Never add `Co-Authored-By`.

## TCA Patterns

- Reducers use `@Reducer`.
- State uses `@ObservableState` and is usually `Equatable`.
- Bindable form features use:
  - `public enum Action: BindableAction`
  - `case binding(BindingAction<State>)`
  - `BindingReducer()`
- Dependencies are accessed through `@Dependency`.
- Async work runs through `.run` and returns through response actions.
- Repeated user-triggered async effects should use cancellation IDs where appropriate.
- Navigation is handled with `StackState` / `StackActionOf` in parent features.
- Child-to-parent events use nested `Delegate` actions.
- Reducers and views must not directly instantiate repositories, services, or use cases.

## Domain Rules

- Domain must not import SwiftUI, ComposableArchitecture, Supabase, Moya, Kakao SDK, Firebase, or other infrastructure SDKs.
- Repository protocols live in `Modules/Domain/Sources/Repositories/`.
- External service ports live in `Modules/Domain/Sources/Ports/`.
- Use cases are plain structs with injected protocols.
- Domain returns Domain entities, never DTOs.

## Data Rules

- Data implementations conform to Domain protocols.
- Supabase row/insert/update types stay inside Data.
- DTOs map to Domain entities with explicit conversion methods.
- Kakao/OpenAI/OpenWeather access stays in Data services/repositories.
- Local fallback cache uses SwiftData models in `Modules/Data/Sources/LocalStore/`.
- Do not hardcode API keys or secrets.

## Dependency Wiring

Dependencies are wired in `App/Sources/ForPApp.swift` through TCA dependency values.

Common registrations include:

- `generateCourseUseCase`
- `fetchRecentCoursesUseCase`
- `fetchEffectivePartnerUseCase`
- `courseRepository`
- `wishlistRepository`
- `userRepository`
- `placeRepository`
- `weatherService`
- `notificationService`
- `currentUserId`

New dependencies should follow the existing pattern in `ForPApp.swift`.

## Review Checklist

- Domain layer has no UI or infrastructure imports.
- Features do not use DTOs or Supabase row types.
- Data does not return DTOs to Domain or Features.
- Async effects update state only through actions.
- Long-running effects have cancellation/termination handling where needed.
- New dependency registrations are present.
- Tuist target dependencies are updated if imports cross module boundaries.
- Force unwraps are avoided.
- Date, coordinate, count, and budget math handles nil, empty arrays, and zero safely.
- User-facing Korean copy is natural and not duplicated.

## Existing Claude Files

This repository may also contain `CLAUDE.md` and `.claude/`.
Those files are for Claude Code compatibility. Codex should treat this `AGENTS.md` as the primary instruction source.

# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Commands

```bash
# Generate or refresh the Tuist workspace
tuist generate

# Open the generated workspace
open ForP.xcworkspace

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

`App/Secrets.xcconfig` and service configuration files must be present for a real app build.

## Architecture

ForP is a Tuist-based modular SwiftUI app using TCA.

```
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
| App | `App/Sources/` | App entry, dependency wiring, SDK setup, SwiftData container |
| Features | `Modules/Features/Sources/` | SwiftUI views and TCA reducers |
| Domain | `Modules/Domain/Sources/` | Entities, repository protocols, ports, use cases |
| Data | `Modules/Data/Sources/` | Supabase, Kakao, OpenAI, weather, local cache implementations |
| CoreNetwork | `Modules/Core/Network/Sources/` | Shared network helpers |
| CoreSharedUI | `Modules/Core/SharedUI/Sources/` | Design tokens and shared UI |

## Key Patterns

### TCA features

- Reducers use `@Reducer`.
- State uses `@ObservableState` and is usually `Equatable`.
- Bindable forms use `public enum Action: BindableAction`, `case binding(BindingAction<State>)`, and `BindingReducer()`.
- Dependencies are accessed through `@Dependency`.
- Long-running effects use `.run` and cancellation IDs when needed.
- Navigation is handled with `StackState` / `StackActionOf` in parent features.
- Child-to-parent events use nested `Delegate` actions.

### Domain

- Domain files should stay UI-free and infrastructure-free.
- Repository protocols live in `Modules/Domain/Sources/Repositories/`.
- External service ports live in `Modules/Domain/Sources/Ports/`.
- Use cases are plain structs with injected protocols, for example `GenerateCourseUseCase`.
- Domain returns Domain entities, never DTOs.

### Data

- Data implementations conform to Domain protocols.
- Supabase row/insert/update types stay inside Data.
- DTOs map to Domain entities with explicit conversion methods.
- Kakao/OpenAI/OpenWeather access stays in Data services/repositories.
- Local fallback cache currently uses SwiftData models in `Modules/Data/Sources/LocalStore/`.

### Dependency registration

Dependencies are wired in `App/Sources/ForPApp.swift` through TCA dependency values:

- repositories: `courseRepository`, `wishlistRepository`, `userRepository`, etc.
- use cases: `generateCourseUseCase`, `fetchRecentCoursesUseCase`, `fetchEffectivePartnerUseCase`
- services: `weatherService`, `notificationService`
- runtime values: `currentUserId`

New dependencies should be registered with the existing pattern rather than being constructed directly inside reducers or views.

## Required Workflow

### New feature or significant behavior change

1. Read the closest existing feature and matching Domain/Data files.
2. Define affected files and data flow before editing.
3. Add or update Domain protocols/entities/use cases first.
4. Add Data implementation and DTO mapping if persistence or API access is needed.
5. Register dependencies in `App/Sources/ForPApp.swift`.
6. Add or update TCA reducer state/actions/effects.
7. Update SwiftUI view composition.
8. Build or test with the narrowest useful command.

### Small fix

- Read the target file first.
- Keep the patch scoped to the requested behavior.
- Do not rewrite style, rename broadly, or refactor unrelated code.

### Commit

- Commit only when the user explicitly asks.
- Use Korean commit messages.
- Prefix with `[feat]`, `[fix]`, `[refactor]`, `[docs]`, or `[test]`.
- Do not add `Co-Authored-By`.

## Review Checklist

- Reducers do not directly instantiate repositories or services.
- Domain does not import SwiftUI, ComposableArchitecture, Supabase, Moya, Kakao SDK, or Firebase.
- Features do not use DTOs or Supabase row types.
- Data does not return DTOs to Domain or Features.
- Async effects update state only through actions.
- Long-running effects are cancellable when user-triggered repeatedly.
- Force unwraps are avoided unless already guaranteed by a local invariant.
- Secrets stay in configuration files and are not hardcoded.

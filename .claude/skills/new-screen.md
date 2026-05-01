---
description: ForP TCA 패턴으로 새 화면 Feature와 View를 추가
---

새 화면 이름: `$ARGUMENTS`

## 생성 위치

- `Modules/Features/Sources/[ScreenName]/[ScreenName]Feature.swift`
- `Modules/Features/Sources/[ScreenName]/[ScreenName]View.swift`

## 기본 Feature 템플릿

```swift
import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct [ScreenName]Feature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }

    public enum Action {
        case onAppear
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
```

## 기본 View 템플릿

```swift
import ComposableArchitecture
import SwiftUI

public struct [ScreenName]View: View {
    @Bindable var store: StoreOf<[ScreenName]Feature>

    public init(store: StoreOf<[ScreenName]Feature>) {
        self.store = store
    }

    public var body: some View {
        Text("[ScreenName]")
            .onAppear {
                store.send(.onAppear)
            }
    }
}
```

## 연결 체크리스트

- 부모 navigation이 필요하면 `HomeFeature.Path`에 case 추가
- 부모 View의 `NavigationStackStore`/destination 처리 확인
- dependency가 필요하면 Domain/Data/App wiring까지 추가
- `Modules/Features/Project.swift` dependency 변경이 필요한지 확인
- 생성 후 build 확인

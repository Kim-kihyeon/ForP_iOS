---
allowed-tools: Bash(git diff:*), Bash(git status:*), Read, Glob, Grep
description: ForP TCA + Tuist 모듈 구조 기준 코드 리뷰
---

## Context

- 변경된 파일: !`git diff HEAD --name-only`
- 변경사항: !`git diff HEAD`

## 리뷰 기준

### 아키텍처

- Domain이 SwiftUI, ComposableArchitecture, Supabase, Moya, Kakao SDK, Firebase를 import하지 않는가?
- Features가 Supabase row, DTO, Data 구현체를 직접 참조하지 않는가?
- Reducer/View에서 repository/service/use case를 직접 생성하지 않는가?
- 새 dependency가 `App/Sources/ForPApp.swift`에 기존 방식으로 등록되었는가?
- App/Project.swift 또는 Modules/*/Project.swift dependency 변경이 필요한데 누락되지 않았는가?

### TCA

- async 작업 결과가 response action으로 돌아오는가?
- 반복 가능한 effect는 cancellation이 필요한지 검토했는가?
- Navigation은 `StackState`/delegate action으로 처리되는가?
- `@ObservableState`, `BindableAction`, `BindingReducer()` 사용이 기존 패턴과 맞는가?

### Data / API

- DTO가 Domain entity로 변환되어 반환되는가?
- Supabase table/column 이름이 기존 row CodingKeys와 일관적인가?
- Kakao/OpenAI/OpenWeather key를 하드코딩하지 않는가?
- 로컬 SwiftData fallback이 있는 repository는 캐시 갱신도 함께 처리하는가?

### Swift 안전성

- 강제 언래핑이 새로 추가되지 않았는가?
- 날짜/좌표/금액 계산에서 nil, 빈 배열, 0 나누기 가능성이 없는가?
- long-running `Task`나 `AsyncStream` termination/cancel 처리가 있는가?

### 코드 품질

- 요청 범위를 벗어난 리팩터링이 없는가?
- 데드 코드, 주석 처리된 코드가 없는가?
- 사용자에게 노출되는 한국어 문구가 어색하거나 중복되지 않는가?

## Your task

위 기준으로 변경된 파일을 리뷰한다. 실제 버그와 잠재적 버그를 우선 보고하고, 문제가 없으면 "이슈 없음"으로 간단히 답한다.

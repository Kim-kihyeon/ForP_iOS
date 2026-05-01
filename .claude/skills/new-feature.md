---
description: ForP의 TCA + Domain/Data 구조에 맞게 새 기능을 설계부터 구현, 검증까지 진행
---

구현할 기능: `$ARGUMENTS`

## 순서

### 1. 설계

`architect` agent를 사용해 아래를 먼저 정리한다.

- 영향받는 Feature/Domain/Data/App 파일
- State, Action, Dependency 설계
- Entity/UseCase/Repository protocol 시그니처
- DTO와 Domain mapping
- dependency registration 위치

### 2. Domain

- `Modules/Domain/Sources/Entities/`에 필요한 entity 추가/수정
- `Modules/Domain/Sources/Repositories/` 또는 `Ports/`에 protocol 추가/수정
- `Modules/Domain/Sources/UseCases/`에 use case 추가/수정
- Domain에 UI/API SDK import 금지

### 3. Data

- DTO 또는 row type 추가/수정
- Repository/Service 구현 추가/수정
- Domain entity로 변환해서 반환
- API key/secret 하드코딩 금지

### 4. App dependency wiring

- `App/Sources/ForPApp.swift`에 repository/service/use case dependency 등록
- 필요하면 Tuist project dependency도 갱신

### 5. Feature

- `Modules/Features/Sources/[Feature]/[Feature]Feature.swift`
- SwiftUI View
- parent navigation 또는 delegate action 연결
- 반복 effect cancellation 검토

### 6. 검증

- 가능한 최소 테스트를 작성/수정
- `build` 또는 `test` skill로 확인
- 커밋은 사용자가 명시적으로 요청할 때만 수행

## 완료 보고

- 변경 파일 목록
- 빌드/테스트 결과
- 남은 리스크

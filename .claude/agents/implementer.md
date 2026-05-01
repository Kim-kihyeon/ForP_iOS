---
name: implementer
description: ForP의 기존 TCA, Domain, Data 패턴을 따라 실제 코드를 구현한다.
---

# Implementer

ForP의 기존 패턴을 먼저 확인한 뒤 코드를 작성한다.

## 사전 확인

- 비슷한 Feature reducer와 View를 읽는다.
- 필요한 Domain UseCase/Repository protocol 패턴을 확인한다.
- Data Repository/DTO mapping 패턴을 확인한다.
- 새 dependency가 필요하면 `App/Sources/ForPApp.swift`의 등록 방식을 확인한다.

## 구현 원칙

### TCA

- Reducer는 `@Reducer`, State는 `@ObservableState`.
- Form 상태는 `BindableAction` + `BindingReducer()`를 사용한다.
- Reducer에서 repository/service를 직접 생성하지 않는다.
- 비동기 작업은 `.run`에서 실행하고 결과는 response action으로 보낸다.
- 반복 실행 가능한 검색/생성 작업은 `.cancellable(id:cancelInFlight:)`를 검토한다.
- 화면 전환은 부모의 `StackState` 또는 delegate action으로 처리한다.

### Domain

- Domain은 UI와 인프라 의존성을 갖지 않는다.
- 프로토콜은 `Modules/Domain/Sources/Repositories` 또는 `Ports`에 둔다.
- UseCase는 injected protocol을 받는 struct로 작성한다.
- DTO를 Domain 밖으로 노출하지 않는다.

### Data

- Data 구현체는 Domain protocol을 구현한다.
- Supabase row/DTO/Encodable helper는 Data 내부에 둔다.
- 네트워크 결과는 Domain entity로 변환해서 반환한다.
- 가능한 경우 기존 SwiftData local fallback 패턴을 유지한다.

### Swift 안전성

- 강제 언래핑을 피한다.
- async closure 캡처는 필요한 값만 캡처한다.
- 사용자가 요청하지 않은 리팩터링, 이름 변경, 주석 추가를 하지 않는다.
- 데드 코드와 주석 처리된 코드를 남기지 않는다.

## 작업 후 체크리스트

- [ ] 레이어 의존성 위반 없음
- [ ] 새 dependency 등록 완료
- [ ] DTO가 Feature/Domain으로 새지 않음
- [ ] user-triggered async effect cancellation 검토
- [ ] secrets hardcoding 없음
- [ ] 관련 빌드 또는 테스트 실행

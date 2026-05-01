---
name: tester
description: ForP의 TCA reducer, Domain use case, repository 단위 테스트를 작성하고 실행한다.
---

# Tester

ForP의 테스트 대상을 분석하고 XCTest 기반 테스트를 작성한다.

## Step 1: 대상 분석

- Feature reducer라면 State, Action, Dependency 목록을 파악한다.
- UseCase라면 주입받는 protocol과 성공/실패 분기를 파악한다.
- Repository라면 Supabase/Kakao/OpenAI 의존성을 mock 가능한 단위로 분리할 수 있는지 확인한다.

## Step 2: 테스트 전략

### TCA reducer

- `TestStore` 사용을 우선 검토한다.
- dependency override로 mock closure 또는 fake implementation을 주입한다.
- action send/receive 순서와 state mutation을 검증한다.

### UseCase

- Domain protocol mock을 작성한다.
- 성공, 실패, edge case를 분리한다.
- 인자 캡처와 call count를 검증한다.

### Repository

- 외부 API 직접 호출 테스트는 피한다.
- pure mapping, local cache fallback, request target construction처럼 고립 가능한 단위를 우선 테스트한다.

## Mock 패턴

```swift
final class MockCourseRepository: CourseRepositoryProtocol {
    var fetchRecentCoursesResult: Result<[Course], Error> = .success([])
    private(set) var fetchRecentCoursesCallCount = 0
    private(set) var capturedUserId: UUID?

    func fetchRecentCourses(userId: UUID, limit: Int) async throws -> [Course] {
        fetchRecentCoursesCallCount += 1
        capturedUserId = userId
        return try fetchRecentCoursesResult.get()
    }
}
```

## 실행

기본 명령:

```bash
xcodebuild test \
  -workspace ForP.xcworkspace \
  -scheme ForP \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

특정 테스트가 가능하면 `-only-testing:`을 붙여 좁게 실행한다.

## 출력

- 작성/수정한 테스트 파일 목록
- 실행한 명령
- 통과/실패 요약
- 실패 시 원인과 수정 내용

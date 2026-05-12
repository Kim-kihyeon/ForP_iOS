# ForP 앱 구조 가이드

이 문서는 ForP의 전체 구조를 빠르게 이해하고, 기능 수정 시 어디를 봐야 하는지 판단하기 위한 가이드입니다.

## 한 줄 요약

ForP는 Tuist 기반 SwiftUI + TCA 앱입니다. 화면 로직은 `Features`, 핵심 모델/유스케이스는 `Domain`, Supabase/Kakao/GPT 같은 외부 연동은 `Data`, 앱 시작과 의존성 연결은 `App`에 있습니다.

## 레이어 구조

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

| 레이어 | 위치 | 역할 |
|---|---|---|
| App | `App/Sources/` | 앱 시작, SDK 설정, TCA dependency wiring, SwiftData container |
| Features | `Modules/Features/Sources/` | SwiftUI 화면, TCA reducer, 화면 상태와 사용자 액션 |
| Domain | `Modules/Domain/Sources/` | Entity, repository protocol, external port, use case |
| Data | `Modules/Data/Sources/` | Supabase, Kakao, GPT, OpenWeather, SwiftData cache 실제 구현 |
| CoreSharedUI | `Modules/Core/SharedUI/Sources/` | 공통 디자인 토큰, 공통 UI 컴포넌트 |
| CoreNetwork | `Modules/Core/Network/Sources/` | 공통 네트워크 도구 |

## 가장 중요한 규칙

- `Domain`은 UI나 인프라를 몰라야 합니다. `SwiftUI`, `ComposableArchitecture`, `Supabase`, `Kakao SDK`, `Firebase`를 import하지 않습니다.
- `Features`는 DTO나 Supabase row를 직접 다루지 않습니다. 화면은 Domain entity만 봅니다.
- `Data`는 외부 API와 DB의 실제 구현을 담당하고, Domain entity로 변환해서 밖으로 내보냅니다.
- Reducer/View 안에서 repository나 service를 직접 만들지 않습니다. `@Dependency`로 받습니다.
- 의존성 실제 연결은 `App/Sources/ForPApp.swift`에서 합니다.
- 커밋은 사용자가 명시적으로 요청할 때만 합니다.

## 코스 생성 흐름

1. `CourseGenerateView`  
   사용자가 동네, 테마, 장소 수, 메모, 찜 장소를 선택합니다.

2. `CourseGenerateFeature`  
   화면 상태를 바탕으로 `CourseOptions`를 만듭니다.  
   최근 저장 장소와 이번 세션에서 이미 나온 장소도 여기서 옵션에 실어 보냅니다.

3. `GenerateCourseUseCase`  
   코스 생성의 핵심 로직입니다.
   - 위치 좌표 확인
   - 날씨 조회
   - GPT 초안 요청
   - Kakao 장소 검색으로 실제 장소 검증
   - 거리, 카테고리, 체인, 중복, 음식 타입 적합성 검사
   - 부족하면 후보에서 보충
   - 최종 순서 정리

4. `GPTAIService`  
   GPT 프롬프트를 만들고 응답을 `CoursePlan` 형태로 파싱합니다.

5. `PlaceSuitabilityScorer`  
   추천 품질 필터입니다.
   - 이상한 이름 필터링: `한식맛집` 같은 일반 검색어성 장소
   - 카테고리 불일치 필터링
   - 브런치/체인카페/패스트푸드 케이스 구분
   - 너무 먼 장소 필터링
   - 최근 나온 장소와 같은 음식 타입에 soft penalty 적용

6. `HomeFeature`  
   생성된 `CoursePlan`을 `Course`로 바꾸고 `CourseResultFeature`로 이동시킵니다.

7. `CourseResultFeature`  
   결과 표시, 저장, 장소 교체, 후보 추가, 진행 모드, 후기 저장을 담당합니다.

## 저장 흐름

```text
CourseResultFeature
  -> SaveCourseUseCase
      -> CourseRepositoryProtocol
          -> SupabaseCourseRepository
```

중요한 점:

- 저장 실패를 `try?`로 숨기면 안 됩니다.
- 사용자가 화면에서 봤던 상태와 서버 상태가 갈라질 수 있는 작업은 alert 또는 retry 경로가 있어야 합니다.
- 장소 재정렬, 후보 추가, 메모 저장, 후기 저장, 진행 체크 저장은 모두 데이터 유실 가능성이 있는 작업입니다.

## 진행 모드 흐름

주요 파일:

- `CourseResultFeature.swift`
- `CourseResultView.swift`
- `HomeFeature.swift`
- `CourseRepositoryProtocol`
- `SupabaseCourseRepository`

상태 필드:

- `Course.status`: `planned`, `inProgress`, `completed`, `cancelled`
- `Course.visitedOrders`: 방문 완료한 장소 순서
- `Course.isEnded`: 과거 호환용 완료 여부

주의할 점:

- 진행 중인 코스는 사용자당 하나만 있어야 합니다.
- 다른 코스를 시작할 때 기존 진행 코스 종료가 실패하면 새 코스를 시작하면 안 됩니다.
- 장소 방문 체크 저장이 실패하면 완료 저장도 이어서 하면 안 됩니다.
- 앱 종료 후 재진입해도 홈의 진행 중 코스와 결과 화면 상태가 일치해야 합니다.

## 인증과 사용자 데이터 흐름

주요 파일:

- `App/Sources/ForPApp.swift`
- `Modules/Data/Sources/Repositories/AuthRepository...`
- `Modules/Data/Sources/Repositories/UserRepository.swift`
- Supabase Edge Function: Kakao auth 관련 함수
- Supabase RLS policy

주의할 점:

- `auth.users.id`와 `public.users.id`가 갈라지면 기존 코스가 안 보입니다.
- RLS는 임시 완화 policy를 오래 두면 안 됩니다.
- 로그인 후 `currentSession`이 실제로 살아있는지 확인해야 합니다.
- Keychain 오류가 나면 세션 저장이 실패할 수 있으므로 fallback storage가 중요합니다.

## 기능별로 먼저 볼 파일

| 작업 | 먼저 볼 파일 |
|---|---|
| 홈 화면 | `HomeView.swift`, `HomeFeature.swift` |
| 온보딩 | `OnboardingView.swift`, `OnboardingFeature.swift` |
| 코스 생성 화면 | `CourseGenerateView.swift`, `CourseGenerateFeature.swift` |
| 추천 품질 | `GenerateCourseUseCase.swift`, `PlaceSuitabilityScorer.swift`, `GPTAIService.swift` |
| 코스 결과 | `CourseResultView.swift`, `CourseResultFeature.swift` |
| 진행 모드 | `CourseResultFeature.swift`, `CourseRepositoryProtocol`, `SupabaseCourseRepository` |
| 저장/조회 | `SaveCourseUseCase.swift`, `FetchRecentCoursesUseCase.swift`, `SupabaseCourseRepository` |
| 찜 | `WishlistManageFeature.swift`, `WishlistRepositoryProtocol`, Data wishlist repository |
| 파트너 | `PartnerFeature.swift`, `PartnerConnectionFeature.swift`, partner repositories |
| 알림 | `SettingsFeature.swift`, notification services, notification settings repositories |
| 로그인 | `LoginFeature.swift`, auth repositories, `UserRepository.swift`, `ForPApp.swift` |

## 새 기능 추가 순서

1. 기존 비슷한 기능을 먼저 읽습니다.
2. 필요한 Domain entity/protocol/use case를 정합니다.
3. DB/API가 필요하면 Data 구현과 DTO mapping을 추가합니다.
4. `ForPApp.swift`에 dependency를 연결합니다.
5. Feature reducer에 State/Action/Effect를 추가합니다.
6. View를 수정합니다.
7. 부모 Feature의 navigation/delegate 연결을 확인합니다.
8. 빌드합니다.

## 버그 수정 순서

1. 증상이 발생한 화면의 Feature/View를 봅니다.
2. 해당 액션이 어떤 use case/repository를 부르는지 따라갑니다.
3. 서버 저장이 관련되면 Data repository와 Supabase schema/RLS도 확인합니다.
4. `try?`로 실패가 숨겨져 있는지 확인합니다.
5. 로컬 상태와 서버 상태가 갈라질 수 있는지 확인합니다.
6. 수정 후 최소 빌드를 돌립니다.

## 코스 추천 품질 체크리스트

- GPT가 만든 이름을 그대로 믿지 않았는가?
- Kakao 검색 결과의 실제 `placeName`, `category`, `address`, `kakaoPlaceId`를 사용했는가?
- `한식맛집`, `카페`, `맛집추천` 같은 일반 검색어성 장소가 걸러지는가?
- 브런치 요청에 일반 체인카페나 메가커피가 분위기 좋은 브런치 카페처럼 설명되지 않는가?
- 같은 동네에서 여러 번 생성해도 같은 장소/같은 음식 타입이 과하게 반복되지 않는가?
- 너무 먼 장소가 음식점/카페로 추천되지 않는가?
- 후보가 부족할 때 전체 실패 대신 가능한 결과를 보여주는가?

## 저장 안정성 체크리스트

- 저장/수정/삭제/진행 체크/후기 저장 실패가 사용자에게 보이는가?
- 실패를 `try?`로 삼키지 않는가?
- 실패했는데 로컬 상태만 성공처럼 바뀌는 곳은 없는가?
- 재시도 가능한 작업은 retry 경로가 있는가?
- 저장된 코스를 수정하면 Supabase에도 즉시 반영되는가?
- 진행 중 코스는 한 사용자에게 하나만 유지되는가?

## 빌드와 검증

```bash
xcodebuild build \
  -workspace ForP.xcworkspace \
  -scheme ForP \
  -destination 'generic/platform=iOS Simulator'
```

자주 보는 기존 warning:

- TCA macro generated code의 Sendable warning
- Firebase Crashlytics run script output warning
- AppIntents metadata skipped warning

이 warning들은 현재 알려진 warning입니다. 새 error가 생기면 우선 그 error를 봅니다.

## 커밋 규칙

- 사용자가 커밋을 요청하기 전에는 커밋하지 않습니다.
- 커밋 메시지는 한국어로 작성합니다.
- prefix는 `[feat]`, `[fix]`, `[refactor]`, `[docs]`, `[test]` 중 하나를 씁니다.
- `Co-Authored-By`는 넣지 않습니다.


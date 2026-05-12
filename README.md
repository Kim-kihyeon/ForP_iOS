# ForP

> P성향 사용자를 위한 AI 기반 데이트 코스 추천 iOS 앱

![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![iOS](https://img.shields.io/badge/iOS-17.0+-blue) ![Xcode](https://img.shields.io/badge/Xcode-26.0+-lightgrey) [![Beta Deploy](https://github.com/Kim-kihyeon/ForP_iOS/actions/workflows/beta.yml/badge.svg)](https://github.com/Kim-kihyeon/ForP_iOS/actions/workflows/beta.yml)

<br>

## 프로젝트 소개

ForP는 데이트 코스를 정하는 과정에서 생기는 선택 피로를 줄이기 위한 iOS 앱입니다.

사용자가 동네, 테마, 장소 수, 요청사항을 입력하면 AI가 코스 초안을 만들고, Kakao Local API로 실제 장소를 다시 검증해 현실적인 코스로 정리합니다. 단순히 GPT가 만든 문장을 보여주는 것이 아니라, 실제 장소명·카테고리·좌표·거리·중복 여부를 확인해 추천 품질을 보정하는 구조를 목표로 했습니다.

이 프로젝트는 초기 제품 방향과 핵심 사용자 흐름을 직접 설계하고, Claude Code와 Codex를 활용해 구현·리팩토링·문서화·안정성 점검을 반복한 AI 협업 기반 제품 개발 프로젝트입니다.

<br>

## 주요 기능

| 기능 | 설명 |
|------|------|
| AI 코스 생성 | 동네, 테마, 장소 수, 메모, 찜 장소를 바탕으로 데이트 코스 생성 |
| 실제 장소 검증 | GPT 초안을 Kakao Local API 검색 결과와 매칭해 실제 장소만 코스에 반영 |
| 추천 품질 보정 | 거리, 카테고리, 체인 여부, 음식 타입, 최근 추천 이력 기반 scoring 적용 |
| 일부 장소 고정 후 재추천 | 마음에 드는 장소는 유지하고 나머지 장소만 다시 추천 |
| 후보 장소 | 선택된 코스 외 대안 장소를 함께 제공하고 결과 화면에서 추가 가능 |
| 코스 저장 및 편집 | 저장한 코스의 장소 순서 변경, 장소 삭제, 후보 추가, 장소별 메모 수정 |
| 데이트 진행 모드 | 저장된 코스를 시작하고 장소별 방문 체크 및 완료 처리 |
| 후기 저장 | 코스 완료 후 평점 없이 메모만 남기는 흐름까지 지원 |
| 찜 목록 | 마음에 드는 장소를 찜하고 코스 생성 조건에 반영 |
| 파트너/프로필 | 내 취향과 파트너 취향을 코스 생성 맥락에 반영 |
| 기념일/알림 | 기념일 관리, 코스 리마인더, FCM 기반 알림 |
| 월간 리포트/발자국 | 완료한 코스를 기반으로 데이트 기록과 방문 지역을 확인 |

<br>

## 추천 파이프라인

```text
사용자 조건 입력
    ↓
CourseGenerateFeature에서 CourseOptions 구성
    ↓
GenerateCourseUseCase
    ├── 위치 좌표 확인
    ├── 날씨 조회
    ├── GPT 코스 초안 생성
    ├── Kakao Local API로 실제 장소 검색
    ├── PlaceSuitabilityScorer로 장소 적합성 평가
    └── 코스 순서 및 후보 장소 정리
    ↓
CourseResultFeature에서 결과 표시, 저장, 재추천, 진행 모드 처리
```

추천 품질을 위해 다음 케이스를 별도로 다뤘습니다.

- `한식맛집`, `카페`, `맛집추천`처럼 일반 검색어에 가까운 장소명 제외
- 브런치 요청에 일반 체인카페가 분위기 좋은 브런치 카페처럼 설명되는 문제 방지
- 같은 동네에서 여러 번 생성할 때 같은 장소나 같은 음식 타입이 반복되는 문제 완화
- 음식점/카페가 기준 위치에서 너무 멀리 추천되는 문제 완화
- GPT 추천 이유를 그대로 쓰지 않고 실제 매칭된 장소 기준으로 설명 재작성

<br>

## 안정성 개선 경험

| 문제 | 개선 |
|------|------|
| Supabase Auth/RLS 문제로 로그인 후 기존 데이터가 보이지 않음 | auth user id, public user row, course user_id 흐름에 로그를 추가해 원인 추적 |
| Keychain session 저장 실패 | Supabase Auth session 저장 경로와 fallback storage 점검 |
| 저장 실패가 `try?`로 숨겨짐 | 코스 편집, 방문 체크, 후기 저장 실패를 alert로 노출 |
| 진행 중 코스가 중복될 가능성 | 기존 진행 코스 종료가 실패하면 새 코스 시작을 막도록 처리 |
| 요청한 장소 수보다 적게 찾으면 전체 실패 | 1곳 이상 검증되면 가능한 결과를 보여주고 부족 안내 표시 |
| 이상한 장소 추천 | `PlaceSuitabilityScorer`로 카테고리, 거리, 체인, 음식 타입, 중복 여부 평가 |

<br>

## 기술 스택

| 분류 | 사용 기술 |
|------|----------|
| 언어 | Swift |
| UI | SwiftUI |
| 아키텍처 | TCA (The Composable Architecture), Clean Architecture 기반 모듈 분리 |
| 모듈화 | Tuist, Swift Package Manager |
| 비동기 | async/await, TCA Effect |
| 백엔드/DB | Supabase Auth, PostgreSQL, RLS, Realtime |
| AI | OpenAI API |
| 장소/지도 | Kakao Local API, MapKit |
| 날씨 | OpenWeather API |
| 인증 | Kakao Login, Apple Sign In |
| 로컬 저장 | SwiftData, UserDefaults, Keychain |
| 푸시/모니터링 | Firebase Cloud Messaging, Firebase Crashlytics |
| 배포 | GitHub Actions, fastlane, fastlane match, TestFlight |
| 협업 도구 | Claude Code, Codex |

<br>

## 프로젝트 구조

```text
ForP/
├── App/
│   ├── Sources/                     # 앱 진입점, SDK 설정, dependency wiring
│   └── Resources/                   # Assets, InfoPlist, Secrets.xcconfig
├── Modules/
│   ├── Core/
│   │   ├── Network/                 # 공통 네트워크 도구
│   │   └── SharedUI/                # 공통 UI, Brand, LoadingView
│   ├── Domain/
│   │   └── Sources/
│   │       ├── Entities/            # Course, User, Partner 등 핵심 모델
│   │       ├── Ports/               # AI, Weather, Notification 등 외부 포트
│   │       ├── Repositories/        # Repository Protocol
│   │       └── UseCases/            # 코스 생성, 저장, 조회 등 비즈니스 로직
│   ├── Data/
│   │   └── Sources/
│   │       ├── DTO/                 # Supabase/API DTO
│   │       ├── Repositories/        # Supabase/Kakao/Auth repository 구현
│   │       ├── Services/            # GPT, Weather, Notification service 구현
│   │       └── LocalStore/          # SwiftData local cache
│   └── Features/
│       └── Sources/
│           ├── App/                 # 앱 루트 Feature
│           ├── Login/
│           ├── Onboarding/
│           ├── Home/
│           ├── CourseGenerate/
│           ├── CourseResult/
│           ├── Wishlist/
│           ├── Profile/
│           ├── Partner/
│           ├── PartnerConnection/
│           ├── Anniversary/
│           ├── Checklist/
│           └── Settings/
├── docs/
│   ├── app-architecture-guide.md
│   ├── auth-rls-checklist.md
│   └── recommendation-quality-roadmap.md
├── supabase/                        # DB migration, Edge Function
├── fastlane/                        # TestFlight 배포 설정
└── .github/workflows/               # GitHub Actions beta deploy
```

<br>

## 핵심 파일

| 영역 | 파일 |
|------|------|
| 앱 의존성 연결 | `App/Sources/ForPApp.swift` |
| 코스 생성 화면 | `Modules/Features/Sources/CourseGenerate/` |
| 코스 결과/진행 모드 | `Modules/Features/Sources/CourseResult/` |
| 홈 화면 | `Modules/Features/Sources/Home/` |
| 추천 유스케이스 | `Modules/Domain/Sources/UseCases/GenerateCourseUseCase.swift` |
| 장소 적합성 평가 | `Modules/Domain/Sources/UseCases/PlaceSuitabilityScorer.swift` |
| GPT 연동 | `Modules/Data/Sources/Services/GPTAIService.swift` |
| 코스 저장/조회 | `Modules/Data/Sources/Repositories/SupabaseCourseRepository.swift` |
| 인증/유저 | `Modules/Data/Sources/Repositories/Auth*`, `UserRepository.swift` |

<br>

## 실행 준비

실제 앱 실행에는 다음 설정 파일과 외부 서비스 키가 필요합니다.

```text
App/Secrets.xcconfig
GoogleService-Info.plist
Supabase project
Kakao native/rest app key
OpenAI API key
OpenWeather API key
Apple Developer / App Store Connect 설정
```

워크스페이스 생성:

```bash
tuist install
tuist generate
```

빌드:

```bash
xcodebuild build \
  -workspace ForP.xcworkspace \
  -scheme ForP \
  -destination 'generic/platform=iOS Simulator'
```

TestFlight 배포:

```bash
bundle exec fastlane beta
```

<br>

## 문서

- [앱 구조 가이드](docs/app-architecture-guide.md)
- [인증/RLS 체크리스트](docs/auth-rls-checklist.md)
- [추천 품질 개선 로드맵](docs/recommendation-quality-roadmap.md)

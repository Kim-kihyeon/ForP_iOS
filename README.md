# ForP

> P성향 사용자를 위한 AI 기반 데이트 코스 추천 iOS 앱

![Swift](https://img.shields.io/badge/Swift-6.0-orange) ![iOS](https://img.shields.io/badge/iOS-17.0+-blue) ![Xcode](https://img.shields.io/badge/Xcode-26.0+-lightgrey) [![Beta Deploy](https://github.com/Kim-kihyeon/ForP_iOS/actions/workflows/beta.yml/badge.svg)](https://github.com/Kim-kihyeon/ForP_iOS/actions/workflows/beta.yml)

[![App Store](https://img.shields.io/badge/App_Store-Download-0D96F6?logo=app-store&logoColor=white)](https://apps.apple.com/us/app/forp/id6762712439)

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


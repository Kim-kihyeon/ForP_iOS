---
allowed-tools: Bash(xcodebuild:*)
description: ForP 앱 빌드 실행
---

ForP 프로젝트를 빌드한다.

```bash
xcodebuild build \
  -workspace ForP.xcworkspace \
  -scheme ForP \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)"
```

결과 처리:

- `BUILD SUCCEEDED`면 성공으로 보고한다.
- `error:`가 있으면 파일/라인과 원인을 요약하고 수정 방향을 제시한다.
- workspace가 없으면 먼저 `tuist generate`가 필요한지 확인한다.

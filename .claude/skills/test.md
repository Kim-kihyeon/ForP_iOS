---
allowed-tools: Bash(xcodebuild:*)
description: ForP 테스트 실행
---

ForP 테스트를 실행한다. `$ARGUMENTS`가 있으면 해당 테스트만 실행한다.

전체 테스트:

```bash
xcodebuild test \
  -workspace ForP.xcworkspace \
  -scheme ForP \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  2>&1 | grep -E "Test Case|error:|FAILED|Executed|passed|failed"
```

특정 테스트:

```bash
xcodebuild test \
  -workspace ForP.xcworkspace \
  -scheme ForP \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:ForPTests/$ARGUMENTS \
  2>&1 | grep -E "Test Case|error:|FAILED|Executed|passed|failed"
```

실패하면 실패한 테스트명, 파일/라인, 실패 메시지, 원인을 요약한다.

# Auth/RLS 재발 방지 체크리스트

작성일: 2026-05-06

## 배경

로그인 후 온보딩이 다시 뜨거나, `Auth session missing`, `new row violates row-level security policy` 오류가 발생하면 인증 세션이 정상적으로 잡히지 않았을 가능성이 높다.

이번 장애의 핵심 원인은 iOS Keychain 저장소 오류였다.

- 로그: `Unspecified Keychain error: -34018`
- 결과: Supabase 세션 저장/조회 실패
- 영향: PostgREST 요청이 authenticated가 아니라 anon으로 나감
- 증상: `users`, `courses` RLS 정책에 막힘

## 앱 코드 확인

### 1. Keychain access group

`App/ForP.entitlements`에 아래 access group이 있어야 한다.

```xml
<key>keychain-access-groups</key>
<array>
  <string>$(AppIdentifierPrefix)com.kihyeonKim.ForP</string>
</array>
```

### 2. Supabase auth storage

`SupabaseClient` 생성 시 auth storage가 명시되어 있어야 한다.

```swift
KeychainLocalStorage(service: "com.kihyeon.ForP.supabase.auth")
```

### 3. 로그인 직후 세션 확인

카카오 로그인 후 아래 상태가 되어야 한다.

- `supabase.auth.currentSession != nil`
- `supabase.auth.user()`가 현재 사용자 id를 반환
- `public.users.id`와 auth user id가 동일

### 4. 클라이언트에서 users upsert 금지

로그인 흐름에서 `public.users`를 클라이언트가 새로 upsert하지 않는다.

사용자 row 생성은 DB trigger 또는 서버/Edge Function 책임으로 둔다.

### 5. 사용자 업데이트는 update만 사용

프로필 수정은 기존 row를 대상으로 update한다.

```swift
.update(row)
.eq("id", value: user.id)
```

`upsert`를 쓰면 id가 갈라지거나 RLS 이슈가 다시 생길 수 있다.

## DB/RLS 확인

### 1. 임시 anon policy 제거 여부

아래 임시 정책이 남아 있으면 안 된다.

```sql
drop policy if exists "users_select_legacy_anon" on public.users;
drop policy if exists "courses_select_legacy_be136" on public.courses;
drop policy if exists "courses_select_legacy_split_ids" on public.courses;
```

### 2. 현재 정책 확인

```sql
select schemaname, tablename, policyname, cmd, roles, qual
from pg_policies
where schemaname = 'public'
  and tablename in ('users', 'courses')
order by tablename, policyname;
```

### 3. 마이그레이션 적용 확인

```sql
select *
from supabase_migrations.schema_migrations
order by version desc;
```

필수 마이그레이션:

- `20260505133000_fix_users_rls_policies`
- `20260505221000_create_user_profile_on_auth_signup`
- `20260505121500_add_course_progress_state`

### 4. 사용자 row 확인

```sql
select *
from public.users
where id = '<auth_user_id>';
```

주의: `users` 테이블에는 `created_at` 컬럼이 없을 수 있으므로 무조건 조회하지 않는다.

### 5. 코스 소유자 확인

```sql
select user_id, count(*)
from public.courses
group by user_id
order by count desc;
```

로그인한 auth user id와 기존 코스의 `user_id`가 같아야 한다.

## 수동 QA

### 로그인

- 앱 삭제 후 재설치
- 카카오 로그인
- 로그인 화면이 반복해서 뜨지 않는지 확인
- 온보딩이 이미 완료된 계정에서 다시 뜨지 않는지 확인
- 홈 화면에 기존 데이터가 보이는지 확인

### 데이터

- 기존 코스 목록이 보이는지 확인
- 기존 찜 목록이 보이는지 확인
- 파트너/기념일 데이터가 보이는지 확인

### 쓰기 동작

- 코스 저장
- 프로필 수정
- 코스 진행 시작
- 진행 상태 변경

위 동작에서 아래 오류가 나오면 안 된다.

- `Auth session missing`
- `new row violates row-level security policy for table "users"`
- `new row violates row-level security policy for table "courses"`

## 로그 기준

정상 로그인 시 최소한 아래 상태를 만족해야 한다.

```text
currentSession=true
fetchUserRow 성공
FETCH CURRENT USER ID == public.users.id
```

아래 로그가 반복되면 Keychain entitlement 또는 auth storage 설정을 먼저 본다.

```text
FORP AUTH STORAGE primary retrieve failed: Unspecified Keychain error: -34018.
```

## 배포 전 금지 사항

- 임시 anon RLS policy를 배포 상태로 남기지 않는다.
- 인증 문제를 피하려고 클라이언트에서 `users.upsert`를 다시 추가하지 않는다.
- 세션 확인 없이 `users`, `courses` 쓰기 요청을 보내지 않는다.
- auth user id와 public user id가 다를 때 데이터를 새로 만들지 않는다.


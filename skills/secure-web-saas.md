# Secure Web SaaS - 바이브코딩용 보안 프롬프트 스킬

## 트리거 조건
사용자가 웹 SaaS 기능 개발을 요청할 때 (특히 바이브코딩, 신규 기능, API 개발 등) 이 스킬의 보안 요구사항을 반드시 포함하여 개발한다.

## 사용법
- 기능 개발 요청 시 `/secure-web-saas` 로 호출
- agent-teams와 함께 사용 가능: 개발 에이전트가 이 보안 기준을 반영하고, 검수자가 검증

## 보안 요구사항 (전부 반영 필수)

아래 15개 항목을 **모두** 코드에 반영하고, **테스트까지 통과한 결과만** 제출할 것.

### 1. CORS / Preflight
- 허용 도메인을 명시적으로 지정 (와일드카드 `*` 금지)
- `Access-Control-Allow-Methods`, `Access-Control-Allow-Headers` 명시
- Preflight 캐시 (`Access-Control-Max-Age`) 설정
- credentials 사용 시 `Access-Control-Allow-Credentials: true` + 정확한 Origin 매칭

### 2. CSRF (Cross-Site Request Forgery)
- SameSite 쿠키 속성 설정 (Strict 또는 Lax)
- 상태 변경 요청(POST/PUT/DELETE)에 CSRF 토큰 적용
- Double Submit Cookie 또는 Synchronizer Token 패턴 사용
- API 전용인 경우 Custom Header 검증 (예: `X-Requested-With`)

### 3. XSS + CSP (Content Security Policy)
- 모든 사용자 입력 HTML 이스케이프 처리
- `Content-Security-Policy` 헤더 설정:
  - `default-src 'self'`
  - `script-src 'self'` (인라인 스크립트 차단)
  - `style-src 'self' 'unsafe-inline'` (필요 시)
  - `img-src 'self' data: https:`
  - `frame-ancestors 'none'` (클릭재킹 방지)
- `X-Content-Type-Options: nosniff`
- `X-XSS-Protection: 0` (CSP로 대체)

### 4. SSRF (Server-Side Request Forgery)
- 사용자 입력 URL에 대해 allowlist 기반 필터링
- 내부 IP 대역 차단 (10.x, 172.16-31.x, 192.168.x, 127.x, 169.254.x)
- DNS rebinding 방지: 해석된 IP 검증
- URL 스킴 제한 (http/https만 허용)

### 5. AuthN / AuthZ (인증/인가)
- JWT 토큰 서명 검증 (알고리즘 고정, `none` 알고리즘 차단)
- 토큰 만료 시간 검증 (`exp` 클레임)
- Refresh Token은 DB에 저장하고 1회 사용 후 폐기 (Rotation)
- 비밀번호 해싱: bcrypt/argon2 사용 (SHA256/MD5 금지)
- OAuth 콜백 URL 검증 (open redirect 방지)

### 6. RBAC/ABAC + 테넌트 격리
- 역할 기반 접근 제어 (Role-Based Access Control) 적용
- 모든 데이터 쿼리에 테넌트 ID 조건 포함
- URL/파라미터의 리소스 ID로 다른 테넌트 데이터 접근 불가하게 검증
- 관리자 엔드포인트 별도 미들웨어로 보호

### 7. 최소 권한 (Least Privilege)
- DB 계정: 필요한 테이블/컬렉션에 대해서만 읽기/쓰기 권한
- API 키: 필요한 스코프만 부여
- 파일 시스템: 업로드 디렉토리만 쓰기 가능
- 컨테이너: non-root 사용자로 실행

### 8. Validation + SQLi 방어
- 모든 입력값 서버 사이드 검증 (타입, 길이, 범위, 패턴)
- 파라미터화된 쿼리 사용 (문자열 결합 쿼리 금지)
- {{DATABASE}} 관련: 사용자 입력을 직접 쿼리 연산자에 사용 금지
- 파일 업로드: MIME 타입 + 확장자 + 매직바이트 검증, 저장 경로 path traversal 방지

### 9. Rate Limit / Bruteforce 방어
- 로그인 시도: IP 기준 5회/분, 계정 기준 10회/시간
- API 호출: 인증 사용자 기준 분당 제한
- 비밀번호 재설정: 시간당 3회 제한
- 429 Too Many Requests 응답 + `Retry-After` 헤더
- 슬라이딩 윈도우 또는 토큰 버킷 알고리즘 사용

### 10. 쿠키 보안 + 세션
- `HttpOnly`: JavaScript에서 접근 불가
- `Secure`: HTTPS에서만 전송
- `SameSite=Lax` 또는 `Strict`
- 세션 고정(Session Fixation) 방지: 로그인 시 세션 ID 재생성
- 세션 타임아웃: 유휴 30분, 절대 24시간

### 11. Secret 관리 + Rotation
- 소스 코드에 시크릿 하드코딩 금지
- 환경변수 또는 Secret Manager(Vault, K8s Secrets)로 관리
- JWT 서명키, API 키는 주기적 Rotation 가능하게 설계
- `.env` 파일 `.gitignore`에 포함

### 12. HTTPS / HSTS + 보안 헤더
- 모든 통신 HTTPS 강제 (HTTP → HTTPS 리다이렉트)
- `Strict-Transport-Security: max-age=31536000; includeSubDomains`
- `X-Frame-Options: DENY`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy: camera=(), microphone=(), geolocation=()`

### 13. Audit Log (감사 로그)
- 로그인/로그아웃 이벤트 기록
- 권한 변경, 데이터 삭제 등 민감 작업 기록
- 로그에 사용자 ID, IP, 타임스탬프, 액션, 결과 포함
- 로그에 비밀번호, 토큰 등 민감 정보 절대 포함 금지
- 로그 위변조 방지 (append-only)

### 14. 에러 노출 차단
- 프로덕션에서 스택 트레이스 노출 금지
- 에러 응답에 내부 구현 상세 포함 금지
- 일관된 에러 응답 형식 (예: `{ "error": "메시지", "code": "ERROR_CODE" }`)
- DB 에러, 파일 경로 등 내부 정보 마스킹
- 404와 403을 구분하지 않고 `404 Not Found`로 통일 (리소스 존재 여부 은닉)

### 15. 의존성 취약점 점검
- 의존성 취약점 스캔 정기 실행
- CI/CD에 취약점 스캔 단계 추가
- 알려진 취약점이 있는 패키지 사용 금지
- lockfile 커밋
- 의존성 업데이트 자동화 (Dependabot/Renovate)

## 검증 체크리스트

개발 완료 후 아래 항목 전부 확인:

- [ ] CORS: 허용 도메인 명시, 와일드카드 미사용
- [ ] CSRF: 상태 변경 API에 방어 적용
- [ ] XSS: 사용자 입력 이스케이프, CSP 헤더 설정
- [ ] SSRF: 외부 URL 요청 시 내부 IP 차단
- [ ] AuthN/AuthZ: JWT 검증, 토큰 만료 체크
- [ ] RBAC: 역할 기반 접근 제어, 테넌트 격리
- [ ] 최소 권한: DB/API/파일 시스템 권한 최소화
- [ ] Validation: 서버 사이드 입력 검증, 파라미터화 쿼리
- [ ] Rate Limit: 로그인/API에 속도 제한 적용
- [ ] 쿠키: HttpOnly, Secure, SameSite 설정
- [ ] Secret: 환경변수/Secret Manager로 관리
- [ ] HTTPS: 보안 헤더 전체 설정
- [ ] Audit Log: 민감 작업 로깅
- [ ] 에러: 스택 트레이스/내부 정보 미노출
- [ ] 의존성: 취약점 없음 확인

## 출력 형식

**테스트까지 통과한 결과만 달 것.**
- 구현된 코드
- 보안 체크리스트 통과 결과
- 실패 항목이 있으면 수정 후 재검증

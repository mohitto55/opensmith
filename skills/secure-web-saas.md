---
name: secure-web-saas
description: "웹 SaaS 보안 15항목 강제 체크리스트. execute step7(QA)에서 자동 실행. 전부 PASS해야 배포 가능. CORS, CSRF, XSS, SSRF, AuthN/AuthZ, RBAC, SQLi, RateLimit, 쿠키, Secret, HTTPS, AuditLog, 에러노출, 의존성 취약점."
allowed-tools: Bash(*), Read, Glob, Grep, Agent
---

# 웹 SaaS 보안 15항목 체크리스트

**이 체크리스트는 step7(QA)에서 강제 실행됩니다. 전부 PASS해야 step8(배포)로 넘어갑니다.**
**전부 반영하고 테스트까지 통과한 결과만 달라고 명시할 것.**

---

## 검사 방법

각 항목에 대해:
1. **코드 grep** — 위반 패턴 검색
2. **설정 파일 확인** — 올바른 설정인지 검증
3. **PASS/FAIL 판정** — 근거와 함께
4. **FAIL 시** — 즉시 코드 수정 → 재검사 (3단계 에스컬레이션 적용)

---

## 1. CORS / Preflight

```bash
grep -rn "AllowAnyOrigin\|Access-Control-Allow-Origin.*\*\|cors.*\*" --include="*.{cs,ts,js,py,go,java}" .
```

| 체크 | 기준 |
|------|------|
| 와일드카드 `*` 사용 안 함 | FAIL if found |
| 허용 오리진 명시적 목록 | 코드에서 확인 |
| Preflight 캐시 설정 (Access-Control-Max-Age) | 권장 |
| credentials: true 시 와일드카드 절대 불가 | FAIL if both |

## 2. CSRF

```bash
grep -rn "csrf\|antiforgery\|csrftoken\|X-CSRF\|SameSite" --include="*.{cs,ts,js,py,go,java,json}" .
```

| 체크 | 기준 |
|------|------|
| 상태 변경 API(POST/PUT/DELETE)에 CSRF 방어 | 토큰 또는 SameSite=Strict |
| SPA는 SameSite + custom header 조합 | 확인 |

## 3. XSS + CSP

```bash
# 위반 검색
grep -rn "dangerouslySetInnerHTML\|innerHTML\|v-html\|{!!.*!!}\|\.html(\|document\.write\|eval(" --include="*.{tsx,ts,jsx,js,vue,html}" .
# CSP 헤더 확인
grep -rn "Content-Security-Policy\|CSP\|helmet" --include="*.{cs,ts,js,py,go,java,json}" .
```

| 체크 | 기준 |
|------|------|
| dangerouslySetInnerHTML / innerHTML 사용 없음 | FAIL if found (정당한 사유 없으면) |
| 사용자 입력 이스케이프 | 코드 확인 |
| CSP 헤더 설정 | 존재 확인 |
| script-src 'unsafe-inline' 없음 | FAIL if found |

## 4. SSRF

```bash
grep -rn "fetch(\|axios\.\|HttpClient\|requests\.\|http\.Get" --include="*.{cs,ts,js,py,go,java}" . | grep -i "req\.\|body\.\|params\.\|query\."
```

| 체크 | 기준 |
|------|------|
| 사용자 입력이 URL에 직접 들어가지 않음 | 코드 확인 |
| 내부 IP(127.0.0.1, 10.x, 192.168.x) 차단 | allowlist 방식 권장 |

## 5. AuthN / AuthZ (인증/인가)

```bash
# 인증 미들웨어 확인
grep -rn "Authorize\|@auth\|requireAuth\|isAuthenticated\|jwt\|bearer" --include="*.{cs,ts,js,py,go,java}" .
# 보호되지 않은 엔드포인트 검색
grep -rn "app\.\(get\|post\|put\|delete\)\|MapGet\|MapPost\|@router\.\|@app\.route" --include="*.{cs,ts,js,py,go,java}" .
```

| 체크 | 기준 |
|------|------|
| 모든 API에 인증 적용 (public 제외) | 미보호 엔드포인트 목록 확인 |
| JWT 검증 (서명, 만료) | 코드 확인 |
| 리소스 소유권 확인 (IDOR 방지) | 본인 데이터만 접근 |

## 6. RBAC/ABAC + 테넌트 격리

```bash
grep -rn "role\|permission\|tenant\|organization\|isAdmin\|isOwner" --include="*.{cs,ts,js,py,go,java}" .
```

| 체크 | 기준 |
|------|------|
| 역할별 접근 제어 존재 | 코드 확인 |
| 멀티테넌트 시 테넌트 ID 필터 필수 | DB 쿼리에 tenant 조건 확인 |
| 관리자 기능 분리 | admin 라우트 보호 확인 |

## 7. 최소 권한

| 체크 | 기준 |
|------|------|
| DB 접속 계정이 root/admin 아님 | 환경변수 확인 |
| 클라우드 IAM 최소 권한 | 설정 확인 |
| 파일 시스템 쓰기 범위 제한 | 코드 확인 |

## 8. Validation + SQLi 방어

```bash
# SQL injection 취약 패턴
grep -rn '\"SELECT.*\+\|\"INSERT.*\+\|\"UPDATE.*\+\|\"DELETE.*\+\|f"SELECT\|f"INSERT' --include="*.{cs,ts,js,py,go,java}" .
# Raw query 사용
grep -rn "rawQuery\|FromSqlRaw\|execute.*sql\|text(" --include="*.{cs,ts,js,py,go,java}" .
```

| 체크 | 기준 |
|------|------|
| 문자열 연결로 SQL 구성 없음 | FAIL if found |
| 파라미터 바인딩 사용 | ORM/PreparedStatement |
| 입력 유효성 검사 (길이, 타입, 범위) | API 경계에서 검증 |

## 9. Rate Limit / Bruteforce

```bash
grep -rn "rateLimit\|throttle\|RateLimiter\|slowDown\|Throttle" --include="*.{cs,ts,js,py,go,java,json}" .
```

| 체크 | 기준 |
|------|------|
| 로그인 엔드포인트 rate limit | 존재 확인 |
| API 전체 rate limit | 존재 확인 |
| 실패 횟수 제한 (계정 잠금) | 로그인 관련 확인 |

## 10. 쿠키 (HttpOnly·Secure·SameSite) + 세션 보안

```bash
grep -rn "cookie\|Set-Cookie\|httpOnly\|secure\|sameSite\|session" --include="*.{cs,ts,js,py,go,java,json}" .
```

| 체크 | 기준 |
|------|------|
| HttpOnly: true | 인증 쿠키 필수 |
| Secure: true | HTTPS 환경 필수 |
| SameSite: Strict 또는 Lax | CSRF 방지 |
| 세션 만료 설정 | 존재 확인 |

## 11. Secret 관리 + Rotation

```bash
# 하드코딩 시크릿
grep -rn 'password\s*=\s*"[^"]{8,}\|secret\s*=\s*"[^"]{8,}\|apikey\s*=\s*"[^"]{8,}\|token\s*=\s*"[^"]{8,}' --include="*.{cs,ts,js,py,go,java,json,yaml,yml}" .
# .env gitignore 체크
grep -q "\.env" .gitignore 2>/dev/null && echo "OK" || echo "FAIL"
# 시크릿 파일 커밋 여부
git ls-files | grep -i "\.env\|\.pem\|\.key\|credentials\|secret" 2>/dev/null
```

| 체크 | 기준 |
|------|------|
| 코드에 시크릿 하드코딩 없음 | FAIL if found |
| .env가 .gitignore에 포함 | FAIL if not |
| .pem/.key 파일 미커밋 | FAIL if committed |
| 환경변수 또는 Secret Manager 사용 | 코드 확인 |

## 12. HTTPS / HSTS + 보안 헤더

```bash
grep -rn "Strict-Transport-Security\|HSTS\|X-Content-Type-Options\|X-Frame-Options\|Referrer-Policy\|helmet" --include="*.{cs,ts,js,py,go,java,json}" .
```

| 체크 | 기준 |
|------|------|
| HSTS 설정 | 존재 확인 |
| X-Content-Type-Options: nosniff | 존재 확인 |
| X-Frame-Options: DENY 또는 SAMEORIGIN | 존재 확인 |
| HTTP → HTTPS 리다이렉트 | 존재 확인 |

## 13. Audit Log

```bash
grep -rn "audit\|AuditLog\|activity.*log\|event.*log" --include="*.{cs,ts,js,py,go,java}" .
```

| 체크 | 기준 |
|------|------|
| 인증 이벤트 로깅 (로그인/로그아웃/실패) | 존재 확인 |
| 데이터 변경 로깅 (CRUD) | 권장 |
| 관리자 행위 로깅 | 권장 |

## 14. 에러 노출 차단

```bash
grep -rn "stackTrace\|stack_trace\|traceback\|\.stack\|DeveloperExceptionPage\|DEBUG.*True" --include="*.{cs,ts,js,py,go,java,json}" .
```

| 체크 | 기준 |
|------|------|
| 프로덕션에서 스택트레이스 노출 안 함 | FAIL if exposed |
| 에러 응답이 내부 정보 미포함 | 코드 확인 |
| 일반적 에러 메시지 반환 | "Something went wrong" 수준 |

## 15. 의존성 취약점 점검

```bash
# 프로젝트에 맞는 명령어 실행
npm audit --production 2>/dev/null | tail -10
pip-audit 2>/dev/null || safety check 2>/dev/null
dotnet list package --vulnerable 2>/dev/null
```

| 체크 | 기준 |
|------|------|
| critical/high 취약점 0개 | FAIL if any |
| 알려진 취약 버전 사용 안 함 | 확인 |

---

## 결과 보고 형식

```
보안 15항목 체크 결과

| # | 항목 | 결과 | 비고 |
|---|------|------|------|
| 1 | CORS/Preflight | PASS/FAIL | [상세] |
| 2 | CSRF | PASS/FAIL | [상세] |
| 3 | XSS+CSP | PASS/FAIL | [상세] |
| 4 | SSRF | PASS/FAIL | [상세] |
| 5 | AuthN/AuthZ | PASS/FAIL | [상세] |
| 6 | RBAC/ABAC+테넌트격리 | PASS/FAIL | [상세] |
| 7 | 최소권한 | PASS/FAIL | [상세] |
| 8 | Validation+SQLi | PASS/FAIL | [상세] |
| 9 | RateLimit/Bruteforce | PASS/FAIL | [상세] |
| 10 | 쿠키+세션보안 | PASS/FAIL | [상세] |
| 11 | Secret관리+Rotation | PASS/FAIL | [상세] |
| 12 | HTTPS/HSTS+보안헤더 | PASS/FAIL | [상세] |
| 13 | AuditLog | PASS/FAIL | [상세] |
| 14 | 에러노출 차단 | PASS/FAIL | [상세] |
| 15 | 의존성 취약점 | PASS/FAIL | [상세] |

전체: N/15 PASS
```

**FAIL이 1개라도 있으면 즉시 수정 후 재검사. 15/15 PASS한 결과만 step8(배포)로 넘어갑니다.**
**3단계 에스컬레이션 적용: 1~2회 실패 → 소프트 알림, 3~5회 → 에이전트 자동 수정, 6회+ → 강제 차단 + 알림**

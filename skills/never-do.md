# NEVER DO — {{PROJECT_NAME}} 통합 금지 규칙

이 문서는 프로젝트 전체에 적용되는 금지 규칙을 정의합니다.
이 규칙들은 자가개선 루프에 의해 자동으로 추가될 수 있습니다.

---

## 프론트엔드 NEVER DO

### UI/컴포넌트

# Customize: Add your frontend UI forbidden patterns
# Example entries:

| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| F1 | [금지 UI 패턴 1] | [이유] | [대안] |
| F2 | [금지 UI 패턴 2] | [이유] | [대안] |
| F3 | `any` 타입 사용 금지 | 타입 안전성 파괴 | 구체적 타입 정의 |
| F4 | 단일 컴포넌트 500줄 초과 금지 | 유지보수 어려움 | 커스텀 훅/서브 컴포넌트 분리 |

### API/데이터

# Customize: Add your frontend API forbidden patterns

| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| F5 | API URL 하드코딩 금지 | 환경별 차이 | 환경변수 사용 |
| F6 | API 에러 무시(empty catch) 금지 | 디버깅 불가 | 최소 로깅 |

---

## 백엔드 NEVER DO

### 아키텍처

# Customize: Add your backend architecture forbidden patterns

| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| B1 | [금지 아키텍처 패턴 1] | [이유] | [대안] |
| B2 | 엔드포인트에서 직접 DB 접근 금지 | 서비스 레이어 우회 | 서비스 통해서만 DB 접근 |
| B3 | 동기 DB 호출 금지 | 스레드 블로킹 | async 메서드 사용 |
| B4 | 검증 로직 복붙 금지 | 유지보수 어려움 | 공통 validator 추출 |

### 보안

| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| B5 | 비밀번호/토큰 하드코딩 금지 | 보안 위험 | 환경변수/Secret Manager |
| B6 | wildcard CORS `*` 금지 | CSRF 위험 | 명시적 origin 지정 |
| B7 | MD5/SHA256 비밀번호 해싱 금지 | 무차별 대입 취약 | bcrypt/argon2 |
| B8 | dev 엔드포인트 프로덕션 노출 금지 | 무인증 접근 | 환경 가드 필수 |
| B9 | 에러 무시(empty catch) 금지 | 디버깅 불가 | 로깅 필수 |

### 데이터

| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| B10 | DTO와 Model 혼용 금지 | 내부 필드 노출 | 분리된 DTO 정의 |

---

## 인프라 NEVER DO

| # | 규칙 | 이유 | 대안 |
|---|------|------|------|
| I1 | `.env` 파일 커밋 금지 | 비밀 정보 노출 | .gitignore에 추가 |
| I2 | `node_modules` 커밋 금지 | 불필요한 크기 | .gitignore에 추가 |
| I3 | 빌드 아티팩트 커밋 금지 | 불필요한 크기 | .gitignore에 추가 |
| I4 | K8s Secret을 평문으로 저장 금지 | 보안 위험 | base64 인코딩 + RBAC |
| I5 | `--force` push 금지 | 히스토리 손실 | 일반 push + merge |

---

## 자동 추가 영역

아래 규칙들은 자가개선 루프(`/self-improve`)에 의해 자동으로 추가됩니다.
각 규칙에는 추가 날짜와 원인 커밋이 기록됩니다.

<!-- AUTO-GENERATED RULES START -->
<!-- 자가개선 루프가 이 영역에 새 규칙을 추가합니다 -->

| AUTO01 | 전역 상태 파일(state.json 등)을 여러 Claude Code 세션이 공유하게 두지 말 것 | 동시 세션이 서로의 상태를 덮어쓰면 파이프라인 진행 정보가 유실된다 | 세션별 경로(`state-{CLAUDE_SESSION_ID}.json`)로 분리하거나 SQLite/TaskList 같은 동시쓰기 안전 저장소 사용 (2026-04-23, self-improve 팩트 dd17f5de) |
| AUTO02 | Stop 훅에서 `cat <<PROMPT` 로 Claude에게 지시를 출력하는 패턴 금지 | Stop 이벤트는 모델 턴이 종료된 뒤 발화되므로 출력된 지시를 Claude가 읽고 수행할 수 없다 — 사실상 데드코드 | SessionStart/SessionEnd 훅에서 Python 등 독립 스크립트가 직접 DB를 쓰게 하거나, 지시 주입이 필요하면 UserPromptSubmit 훅에서 additionalContext 반환 (2026-04-23, self-improve 팩트 d33c3866) |
| AUTO03 | SKILL.md에 실제로 실행해보지 않은 명령·플래그·경로를 적지 말 것 | init-memory SKILL에 `--skip-extract` 같은 허구 플래그와 단독 실행 불가한 `setup.sh` 호출이 문서화되어 유저가 따라하면 즉시 실패했음 | 각 명령을 프로젝트에서 한 번 실행해 exit code와 경로를 확인한 뒤 문서화. 플래그는 `script --help` 출력과 맞출 것 (2026-04-23, self-improve 팩트 38c6ef29 파생) |

<!-- AUTO-GENERATED RULES END -->

---

## 관련 문서
- [frontend-patterns.md](./frontend-patterns.md) - 프론트엔드 패턴
- [backend-patterns.md](./backend-patterns.md) - 백엔드 패턴

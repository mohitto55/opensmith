# /team 오케스트레이터 (6역할 × 6 Phase)

## 개요

기존 `/agent-teams`의 3역할(백엔드/프론트엔드/검수)을 6역할 × 6 Phase로 확장합니다.
각 역할은 명확한 Phase에서만 활성화되며, 프론트엔드와 백엔드는 Phase 3에서 병렬 실행됩니다.

---

## 역할 정의

### 1. 팀 리더 (Team Lead)

**전 Phase 활성** — 오케스트레이션 담당

| Phase | 동작 |
|-------|------|
| Phase 0 (분석) | Orchestrate: 요구사항 분석, 역할 배정 |
| Phase 1 (설계) | Coordinate: 설계자와 협업, 설계 검증 |
| Phase 2 (DB) | Monitor: DB 관리자 작업 모니터링 |
| Phase 3 (구현) | Coordinate: 프론트/백엔드 병렬 작업 조율 |
| Phase 4 (QA) | Review: QA 결과 검토, 이슈 우선순위 결정 |
| Phase 5 (배포) | Ship: 최종 승인, 배포 실행 |

### 2. 설계자 (Architect)

**Phase 0~1 활성** — 시스템 설계 담당

| Phase | 동작 |
|-------|------|
| Phase 0 | Brief: 요구사항 문서를 읽고 기술 브리프 작성 |
| Phase 1 | 설계: API 설계, 데이터 모델, 컴포넌트 구조 설계 |

**출력물**:
- API 명세서 (엔드포인트, 요청/응답 형태)
- 데이터 모델 ({{DATABASE}} 스키마)
- 컴포넌트 구조도 (React 컴포넌트 트리)
- 기술 결정 문서 (선택한 기술과 이유)

### 3. DB 관리자 (DB Admin)

**Phase 1~2 활성** — 데이터베이스 담당

| Phase | 동작 |
|-------|------|
| Phase 1 | Schema: 설계자의 데이터 모델을 기반으로 {{DATABASE}} 스키마 확정 |
| Phase 2 | Migrate + RLS: 마이그레이션 스크립트 작성, 인덱스 설정, 접근 제어 |

**출력물**:
- {{DATABASE}} 컬렉션 스키마 (JSON Schema)
- 인덱스 정의
- 마이그레이션 스크립트 (있는 경우)
- 데이터 시딩 스크립트 (필요 시)

### 4. 프론트엔드 개발자 (Frontend Dev)

**Phase 2~3 활성** — UI 구현 담당

| Phase | 동작 |
|-------|------|
| Phase 2 | Types: TypeScript 타입 정의 (API 응답 타입, Props 타입) |
| Phase 3 | UI Components: React 컴포넌트 + 페이지 구현 |

**기술 스택 제약**:
- {{FRONTEND_FRAMEWORK}} App Router (TypeScript)
- React Server Components 우선
- 클라이언트 컴포넌트는 `'use client'` 명시
- `frontend/app/` 경로 기준
- docs/ 설계 문서 참조

### 5. 백엔드 개발자 (Backend Dev)

**Phase 2~3 활성** — API 구현 담당

| Phase | 동작 |
|-------|------|
| Phase 2 | API Spec: 설계자의 API 명세를 기반으로 OpenAPI 스펙 확정 |
| Phase 3 | API Endpoints: {{BACKEND_FRAMEWORK}} 엔드포인트 + 서비스 구현 |

**기술 스택 제약**:
- C# {{BACKEND_FRAMEWORK}}
- Minimal API 패턴
- `backend/{{PROJECT_NAME}}.API/` 경로 기준
- {{DATABASE}}.Driver 사용
- docs/ 설계 문서 참조

### 6. QA 엔지니어 (QA Engineer)

**Phase 4 활성** — 테스트 담당

| Phase | 동작 |
|-------|------|
| Phase 4 | L0-L5 Tests: 다단계 테스트 실행 |

**테스트 레벨**:

| 레벨 | 이름 | 내용 |
|------|------|------|
| L0 | Smoke | 빌드 성공 + 서버 시작 확인 |
| L1 | Unit | 개별 함수/메서드 단위 테스트 |
| L2 | Integration | API 엔드포인트 통합 테스트 |
| L3 | E2E | 브라우저 기반 시나리오 테스트 (agent-browser) |
| L4 | Performance | 응답 시간 + 메모리 사용량 체크 |
| L5 | Security | OWASP Top 10 취약점 스캔 |

---

## Phase 실행 흐름

```
PHASE 0          PHASE 1         PHASE 2         PHASE 3         PHASE 4       PHASE 5
분석               설계             DB              구현             QA            배포
─────────────────────────────────────────────────────────────────────────────────────────

팀 리더  ──[Orchestrate]──[Coordinate]──[Monitor]──[Coordinate]──[Review]──[Ship ✓]──

설계자   ────[Brief]────[설계]───────────────────────────────────────────────────────

DB 관리자 ───────────────[Schema]──[Migrate+RLS]──────────────────────────────────────

프론트엔드 ──────────────────────────[Types]──[UI Components]───────────────────────────

백엔드   ──────────────────────────[API Spec]──[API Endpoints]───────────────────────

QA       ────────────────────────────────────────────────[L0-L5 Tests]──────────────

         │                                    │
         └── 프론트엔드 + 백엔드               │
             Phase 3에서 Promise.all()        │
             병렬 실행                         │
```

---

## 실행 구현

### Phase 0: 분석

```
팀 리더가 사용자 요구사항을 분석:
1. docs/ 문서 읽기 (architecture.md, features.md, character-system.md 등)
2. 기존 코드 구조 파악
3. 요구사항을 역할별 태스크로 분해
4. 태스크 생성 (TaskCreate)
5. 역할 배정
```

### Phase 1: 설계

```
설계자 에이전트 스폰:
Agent(
  name="architect",
  team_name="crackcopy-team",
  prompt="요구사항을 분석하고 API 설계 + 데이터 모델 + 컴포넌트 구조를 설계하세요.
         출력: docs/에 설계 문서 작성"
)

팀 리더: 설계 결과 검토, system-design-validator 실행
DB 관리자: 설계자 출력물에서 스키마 확정
```

### Phase 2: DB + Type 준비

```
# 순차 실행
DB 관리자: 스키마 + 마이그레이션 + 인덱스
  ↓
# 병렬 실행 준비
프론트엔드: TypeScript 타입 정의
백엔드: API Spec 확정
```

### Phase 3: 구현 (병렬)

```javascript
// Promise.all() 병렬 실행
await Promise.all([
  Agent({ name: "frontend-dev", prompt: "UI Components 구현..." }),
  Agent({ name: "backend-dev", prompt: "API Endpoints 구현..." })
]);
```

**핵심**: 프론트엔드와 백엔드가 동시에 실행됩니다.
Phase 2에서 API Spec과 Types가 확정되었으므로 독립 작업 가능.

### Phase 4: QA

```
QA 에이전트 스폰:
Agent(
  name="qa-engineer",
  prompt="L0~L5 테스트 실행.
         L0: {{BACKEND_FRAMEWORK}} build + npm run build
         L1: 단위 테스트
         L2: API 통합 테스트
         L3: agent-browser E2E 테스트
         L4: 성능 체크
         L5: 보안 스캔"
)
```

### Phase 5: 배포

```
팀 리더:
1. QA 결과 최종 검토
2. deploy 스킬 실행
3. 프로덕션 헬스체크
4. 완료 보고
```

---

## 기존 agent-teams와의 차이

| 항목 | 기존 (agent-teams) | 신규 (/team) |
|------|-------------------|-------------|
| 역할 수 | 3 (백엔드, 프론트, 검수) | 6 (+ 설계자, DB 관리자, QA) |
| Phase 수 | 1 (구현만) | 6 (분석→설계→DB→구현→QA→배포) |
| 설계 단계 | 없음 | Phase 0~1에서 설계 선행 |
| DB 관리 | 각자 알아서 | DB 관리자가 전담 |
| 테스트 | 검수자가 코드 리뷰 | QA가 L0-L5 다단계 테스트 |
| 병렬 실행 | 백엔드/프론트 병렬 | Phase 3에서만 병렬, 나머지 순차 |
| 배포 | 별도 | Phase 5에 통합 |

---

## SKILL.md 업데이트 계획

기존 `agent-teams/SKILL.md`를 `/team` 오케스트레이터로 업그레이드:
- 6역할 프롬프트 템플릿 포함
- Phase 흐름 제어 로직
- 태스크 의존성 자동 관리
- 에스컬레이션 연동

---

## 관련 문서
- [PRD](./prd.md) - 전체 요구사항
- [5-Layer Architecture](./architecture-5layer.md) - 레이어 아키텍처
- [Hook System](./hook-system.md) - 훅 시스템
- [시스템 아키텍처](../architecture.md) - 서비스 인프라

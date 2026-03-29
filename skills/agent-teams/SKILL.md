---
name: agent-teams
description: "6역할 × 6 Phase 팀 오케스트레이터. 설계자/DB관리자/프론트엔드/백엔드/QA + 팀리더가 병렬 협업. 기능 개발, 코드 구현, API 설계, 컴포넌트 개발 등을 요청할 때 사용."
allowed-tools: Agent, Bash(*), Read, Write, Edit, Glob, Grep, TeamCreate, TaskCreate, TaskGet, TaskList, TaskUpdate, SendMessage
argument-hint: "<개발할 기능 요구사항>"
---

# /team — 6역할 오케스트레이터 (LoopyEra)

TeamCreate → TaskCreate → Agent(team_name) 방식으로 6역할 × 6 Phase 팀을 운영합니다.

## 6역할

| 역할 | 활성 Phase | 핵심 임무 |
|------|-----------|-----------|
| 팀 리더 | 전체 | Orchestrate, Coordinate, Monitor, Review, Ship |
| 설계자 | 0-1 | Brief, 설계 (API + 데이터 모델 + 컴포넌트 구조) |
| DB 관리자 | 1-2 | Schema 확정, Migrate + 인덱스 설정 |
| 프론트엔드 | 2-3 | TypeScript 타입 정의, UI Components 구현 |
| 백엔드 | 2-3 | API Spec 확정, API Endpoints 구현 |
| QA | 4 | L0-L5 테스트 (Smoke→Unit→Integration→E2E→Perf→Security) |

## 실행 절차

사용자 요구사항: `$ARGUMENTS`

### Phase 0: 분석 (팀 리더)

**반드시 PRD + 설계 문서를 먼저 확인합니다.**

1. **PRD 확인**: `docs/prd/`에서 해당 기능의 PRD를 찾아 읽는다
   - PRD가 없으면 → **구현을 시작하지 않고** 사용자에게 "PRD가 없습니다. /dev-cycle로 먼저 PRD를 생성해주세요" 안내
   - PRD가 있으면 → 사용자 스토리, 기능 요구사항, 범위를 파악
2. **설계 문서 확인**: `docs/design/`에서 해당 기능의 기술 설계를 찾아 읽는다
   - 설계가 없으면 → **구현을 시작하지 않고** 사용자에게 "설계 문서가 없습니다" 안내
   - 설계가 있으면 → API 명세, 데이터 모델, 컴포넌트 구조를 파악
3. docs/ 문서 읽기 (architecture.md, features.md 등)
4. scaffold 패턴 확인 (frontend-patterns.md, backend-patterns.md, never-do.md)
5. 기존 코드 구조 파악
6. PRD + 설계를 기반으로 요구사항을 역할별 태스크로 분해
7. 팀 생성:

```
TeamCreate(team_name="{{PROJECT_NAME}}-team", description="{{PROJECT_NAME}} 기능 개발")
```

5. 태스크 생성:

```
TaskCreate: 설계 - [요구사항의 설계 부분]
TaskCreate: DB - [스키마/마이그레이션]
TaskCreate: 프론트엔드 - [UI/컴포넌트]
TaskCreate: 백엔드 - [API/서비스]
TaskCreate: QA - [테스트] (blocked by 프론트엔드, 백엔드)
```

### Phase 1: 설계 (설계자 에이전트)

```
Agent(
  name="architect",
  team_name="{{PROJECT_NAME}}-team",
  description="설계",
  subagent_type="general-purpose",
  prompt="당신은 {{PROJECT_NAME}} 프로젝트의 시스템 설계자입니다.
요구사항: [요구사항]

작업:
1. docs/ 설계 문서를 읽으세요
2. API 엔드포인트 설계 (RESTful, /api/v1 접두어)
3. {{DATABASE}} 데이터 모델 설계
4. 프론트엔드 컴포넌트 구조 설계
5. 기술 결정 문서 작성

scaffold 참조:
- .claude/skills/backend-patterns.md
- .claude/skills/frontend-patterns.md
- .claude/skills/never-do.md

완료 후 TaskUpdate로 태스크 완료 처리"
)
```

팀 리더: 설계 결과 검토 → system-design-validator 실행

### Phase 2: DB + Type 준비

**DB 관리자** (순차):
```
Agent(
  name="db-admin",
  team_name="{{PROJECT_NAME}}-team",
  description="DB 관리",
  prompt="당신은 {{PROJECT_NAME}} 프로젝트의 DB 관리자입니다.
설계자의 설계 결과를 기반으로:
1. {{DATABASE}} 스키마 확정
2. 인덱스 설계
3. 데이터 모델 구현

# Customize: Add your database-specific model patterns here
# Example for MongoDB: [BsonIgnoreExtraElements], [BsonElement], [JsonIgnore]
# Example for PostgreSQL: Entity Framework migrations
# Example for MySQL: Sequelize models

scaffold: .claude/skills/backend-patterns.md
완료 후 TaskUpdate"
)
```

**프론트엔드** + **백엔드** (Phase 2 후반 — 타입/스펙 준비):
- 프론트엔드: 타입/인터페이스 정의
- 백엔드: API Spec (엔드포인트, 요청/응답 DTO)

### Phase 3: 구현 (병렬 — Promise.all)

**프론트엔드 + 백엔드 동시 스폰:**

```
Agent(
  name="frontend-dev",
  team_name="{{PROJECT_NAME}}-team",
  description="프론트엔드 개발",
  prompt="당신은 {{PROJECT_NAME}} 프로젝트의 프론트엔드 개발자입니다.
# Customize: Frontend framework patterns
# Example for Next.js: App Router, RSC, 'use client' rules
# Example for React SPA: React Router, state management
# Example for Vue: Composition API, Pinia
- 경로: frontend/
- 반드시 .claude/skills/frontend-patterns.md를 읽고 패턴을 따르세요
- .claude/skills/never-do.md의 금지 규칙을 준수하세요
완료 후 TaskUpdate"
)

Agent(
  name="backend-dev",
  team_name="{{PROJECT_NAME}}-team",
  description="백엔드 개발",
  prompt="당신은 {{PROJECT_NAME}} 프로젝트의 백엔드 개발자입니다.
# Customize: Backend framework patterns
# Example for ASP.NET: Minimal API, MapGroup, service layer
# Example for FastAPI: routers, dependency injection
# Example for Express: routes, middleware
- 경로: backend/
- 반드시 .claude/skills/backend-patterns.md를 읽고 패턴을 따르세요
- .claude/skills/never-do.md의 금지 규칙을 준수하세요
완료 후 TaskUpdate"
)
```

### Phase 4: QA (구현 완료 후)

```
Agent(
  name="qa-engineer",
  team_name="{{PROJECT_NAME}}-team",
  description="QA 테스트",
  prompt="당신은 {{PROJECT_NAME}} 프로젝트의 QA 엔지니어입니다.

L0 Smoke:
  {{BACKEND_BUILD_CMD}}
  {{FRONTEND_BUILD_CMD}}

L1 Unit: (테스트 프레임워크에 따라 실행)

L2 Integration: API 엔드포인트 curl 테스트

L3 E2E: agent-browser로 브라우저 테스트 (시간 허용 시)

L4 Performance: 빌드 시간, 번들 크기 체크

L5 Security:
  - .claude/skills/never-do.md 보안 규칙 위반 grep
  - 하드코딩 시크릿 검색

이슈 발견 시 직접 수정.
완료 후 TaskUpdate"
)
```

### Phase 5: 배포 (팀 리더)

1. QA 결과 최종 검토
2. 모든 태스크 완료 확인
3. 빌드 최종 확인
4. 배포 여부를 사용자에게 질문
5. 승인 시 deploy 스킬 실행

## 조율 규칙

- 팀 리더(메인 세션)가 TaskList를 모니터링
- 각 Phase 완료 시 다음 Phase의 에이전트에게 SendMessage
- QA 반려 시 해당 에이전트에게 피드백 전달
- 3회 연속 반려 → 요구사항 재검토

## 완료 조건

QA 엔지니어가 L0 (빌드 성공) 이상을 통과하면 완료.

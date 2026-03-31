---
name: agent-teams
description: "7역할 × 6 Phase 팀 오케스트레이터. 설계자/UI디자이너/DB관리자/프론트엔드/백엔드/QA + 팀리더가 병렬 협업. 기능 개발, 코드 구현, API 설계, 컴포넌트 개발 등을 요청할 때 사용."
allowed-tools: Agent, Bash(*), Read, Write, Edit, Glob, Grep, TeamCreate, TaskCreate, TaskGet, TaskList, TaskUpdate, SendMessage
argument-hint: "<개발할 기능 요구사항>"
---

# /team — 7역할 오케스트레이터 (OpenSmith)

TeamCreate → TaskCreate → Agent(team_name) 방식으로 7역할 × 6 Phase 팀을 운영합니다.

## 7역할

| 역할 | 활성 Phase | 핵심 임무 |
|------|-----------|-----------|
| 팀 리더 | 전체 | Orchestrate, Coordinate, Monitor, Review, Ship |
| 설계자 | 0-1 | Brief, 설계 (API + 데이터 모델) |
| UI 디자이너 | 1-2 | 와이어프레임, 컴포넌트 명세, 상태 정의, 반응형 |
| DB 관리자 | 1-2 | Schema 확정, Migrate + 인덱스 설정 |
| 프론트엔드 | 2-3 | UI 명세 기반 컴포넌트 구현, 타입 정의 |
| 백엔드 | 2-3 | API Spec 확정, API Endpoints 구현 |
| QA | 4 | L0-L5 테스트 (Smoke→Unit→Integration→E2E→Perf→Security) |

## 사전 조건: Agent Teams 환경 변수 확인

**Agent Teams 실행 전 반드시 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 환경 변수가 설정되어 있는지 확인하세요.**

```bash
echo $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
```

값이 `1`이 아니면 **즉시 중단**하고 사용자에게 다음을 안내하세요:

> ⚠️ Agent Teams 기능이 활성화되어 있지 않습니다.
> Claude Code의 `settings.json`에 아래 설정을 추가해주세요:
> ```json
> {
>   "env": {
>     "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
>   }
> }
> ```
> 설정 파일 위치: `~/.claude/settings.json` 또는 프로젝트의 `.claude/settings.json`

환경 변수가 확인된 후에만 아래 실행 절차를 진행합니다.

---

## ⛔ 절대 금지 규칙

1. **TeamCreate 생략 금지** — 어떤 작업이든 반드시 `TeamCreate`로 팀을 생성해야 한다. "간단한 작업", "프론트엔드 전용", "파일 하나 수정" 등의 이유로 팀 생성을 건너뛰지 마라.
2. **Phase 건너뛰기 금지** — Phase 0→1→2→3→4→5 순서를 반드시 따른다. 불필요한 역할은 해당 Phase에서 "해당 없음"으로 처리하되, Phase 자체를 생략하지 마라.
3. **QA 생략 절대 금지** — 어떤 규모의 작업이든 QA 에이전트는 반드시 스폰한다. QA 없이 완료 처리하는 것은 금지다.
4. **임의 판단으로 축소 금지** — "최소화", "바로 구현", "팀 구성 생략" 등의 자체 판단은 금지다. 문서에 정의된 절차를 그대로 실행하라.
5. **subagent 직접 스폰 금지** — `Agent()`를 `team_name` 없이 단독으로 호출하지 마라. 모든 에이전트는 반드시 팀 소속이어야 한다.

위 규칙을 위반하면 전체 작업을 처음부터 다시 시작한다.

---

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
TaskCreate: UI - [와이어프레임/컴포넌트 명세]
TaskCreate: DB - [스키마/마이그레이션]
TaskCreate: 프론트엔드 - [UI 명세 기반 컴포넌트 구현] (blocked by UI, DB)
TaskCreate: 백엔드 - [API/서비스] (blocked by DB)
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

### Phase 2: DB + UI 디자인 (병렬)

**DB 관리자** + **UI 디자이너** 동시 스폰:

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

Agent(
  name="ui-designer",
  team_name="{{PROJECT_NAME}}-team",
  description="UI 디자인",
  prompt="당신은 {{PROJECT_NAME}} 프로젝트의 UI 디자이너입니다.
설계자의 설계 결과와 PRD의 사용자 스토리를 기반으로:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UI 디자인 기본 원칙 (반드시 준수)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

■ 그리드 시스템
- 8px 그리드 사용. 모든 간격/크기는 8의 배수 (8, 16, 24, 32, 40, 48...)
- 작은 요소(아이콘, 텍스트 내부)는 4px 그리드 허용
- 모바일: 4컬럼 또는 6컬럼 그리드
- 좌우 마진: 모바일 16px, 태블릿 24px, 데스크톱 32px+
- 컬럼 간 거터: 16px

■ 정렬 (가장 중요!)
- 모든 요소는 반드시 좌측/중앙/우측 중 하나로 정렬
- 같은 그룹의 요소는 같은 정렬선 공유 (좌측 가장자리가 일치)
- 중앙 정렬: 짧은 제목, 헤더, CTA 버튼, 빈 상태 메시지에만 사용
- 본문 텍스트는 반드시 좌측 정렬 (중앙 정렬 금지)
- 수직 중앙 정렬: 아이콘+텍스트 조합, 모달 내부, 빈 상태 화면
- 버튼 내부 텍스트는 반드시 수직·수평 중앙 정렬
- 카드/리스트 아이템 내부 요소는 수직 중앙 정렬

■ 간격 (Spacing)
- padding(내부 간격) ≤ margin(외부 간격): 컴포넌트 내부 < 컴포넌트 사이
- 관련 요소는 가깝게, 비관련 요소는 멀게 (근접성 원칙)
- 섹션 간: 32~48px
- 요소 간 (같은 그룹): 8~16px
- 컴포넌트 내부 padding: 12~16px
- 버튼 padding: 수직 12px, 수평 24px (최소 터치 영역 48x48px)

■ 타이포그래피 위계
- H1: 24~32px, Bold (페이지 제목, 1개만)
- H2: 20~24px, SemiBold (섹션 제목)
- H3: 16~18px, Medium (서브섹션)
- Body: 14~16px, Regular (본문)
- Caption: 12px, Regular (보조 텍스트)
- 줄 높이(line-height): 폰트 크기 × 1.4~1.6
- 한 화면에 폰트 크기 3~4종류만 사용

■ 색상
- Primary: 1개 (브랜드 컬러, CTA 버튼, 링크)
- Secondary: 1개 (보조 동작)
- 배경: 1~2개 (화이트/그레이 또는 다크 테마)
- 텍스트: 최대 3단계 (주요 #000/fff, 보조 #666/aaa, 비활성 #999/666)
- 상태 색상: Success(초록), Error(빨강), Warning(주황), Info(파랑)
- 대비율: 텍스트 최소 4.5:1 (WCAG AA)

■ 터치 타겟 (모바일)
- 최소 터치 영역: 48x48dp (Android), 44x44pt (iOS)
- 터치 타겟 사이 최소 간격: 8dp
- 화면 하단에 주요 동작 배치 (엄지 접근성)

■ 시각적 위계
- 가장 중요한 동작(CTA)은 가장 눈에 띄게 (크기, 색상, 위치)
- 보조 동작은 outline/ghost 버튼
- 파괴적 동작(삭제)은 빨간색, 확인 단계 필수

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
산출물 형식
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 페이지별 와이어프레임 (텍스트 기반 레이아웃)
   - 각 페이지의 영역 배치, 주요 요소 위치
   - 모든 요소에 px 단위 간격 명시 (8px 그리드 기준)
   - 정렬 방식 명시 (left/center/right)

2. 컴포넌트 명세
   - 컴포넌트명, props, 내부 상태
   - 사용자 인터랙션 (클릭, 호버, 입력 등)
   - 컴포넌트 간 데이터 흐름
   - 내부 padding, 외부 margin 명시

3. 상태 정의
   - 로딩 상태: 스켈레톤/스피너 위치 (중앙 정렬)
   - 에러 상태: 에러 메시지 표시 방식 (아이콘 + 텍스트 중앙 정렬)
   - 빈 상태: 일러스트 + 메시지 + CTA 수직 중앙 정렬
   - 성공 상태: 토스트/알림 방식

4. 반응형 브레이크포인트
   - 모바일 (< 768px): 1컬럼, 좌우 마진 16px
   - 태블릿 (768-1024px): 2컬럼, 좌우 마진 24px
   - 데스크톱 (> 1024px): 콘텐츠 최대 너비 1200px, 중앙 정렬

5. 색상/타이포 가이드
   - 위 원칙에 따른 색상 팔레트
   - 폰트 크기 체계 (H1~Caption)

산출물을 docs/prd/features/[기능명]/ui-spec.md 에 저장하세요.
scaffold: .claude/skills/frontend-patterns.md
완료 후 TaskUpdate"
)
```

팀 리더: DB + UI 완료 대기 후 Phase 3로

### Phase 3: 구현 (병렬 — Promise.all)

**프론트엔드 + 백엔드 동시 스폰:**

```
Agent(
  name="frontend-dev",
  team_name="{{PROJECT_NAME}}-team",
  description="프론트엔드 개발",
  prompt="당신은 {{PROJECT_NAME}} 프로젝트의 프론트엔드 개발자입니다.

**반드시 UI 디자이너의 명세를 먼저 읽으세요:**
- docs/prd/features/[기능명]/ui-spec.md

UI 명세의 와이어프레임, 컴포넌트 명세, 상태 정의, 반응형 규칙을 그대로 구현합니다.
명세에 없는 UI를 임의로 만들지 마세요.

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

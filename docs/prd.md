# LoopyEra PRD (Product Requirements Document)

## 1. 문제 정의

### 현재 병목
{{PROJECT_NAME}} 프로젝트는 현재 **사람이 모든 실행의 중심**에 있습니다:
- 코드 작성 후 빌드 에러 → 사람이 확인하고 지시
- 스킬/훅 추가 → 사람이 직접 설계하고 검토
- 배포 후 QA → 사람이 브라우저 테스트 지시
- 코드 패턴 위반 → 사람이 발견하고 수정 요청

### 목표 상태
**사람은 방향만 설정하고, 시스템이 자율적으로 실행·검증·학습·개선**하는 아키텍처.

---

## 2. 기능 요구사항 (Functional Requirements)

### FR-1: 5개 레이어 아키텍처

| 레이어 | 역할 | 구성 요소 |
|--------|------|-----------|
| **사용자** | 방향 설정, 피드백, 양질의 정보 | HARD 차단 시에만 텔레그램 알림 |
| **{{AI_MODEL}}** | Opus 메인 스레드 + 오케스트레이터 + 65개 스킬 + 전문 에이전트 | bypassPermissions, 7개 전문가 |
| **훅** | 11개 이벤트에 30개 훅 | HARD 게이트 차단, Agent 훅 자동 수정, SOFT 훅 가이드 주입 |
| **메모리** | 시맨틱 검색 2,600+ 팩트 | Memory Bank, 세션 상태 유지, 프로젝트 scaffold, 에러 로그 → self-improve |
| **인프라** | Git, npm/tsc/vitest, SQLite + sqlite-vec, 텔레그램 봇, MCP 서버 | Git, SQLite, Telegram, MCP |

### FR-2: 프롬프트 컨텍스트 스택 (5-Layer Context Assembly)

모든 {{AI_MODEL}} 프롬프트는 이미 풍부한 컨텍스트 위에서 실행됩니다:

```
Layer 5: 사용자 프롬프트 (TOP)
  └─ 사용자가 타이핑한 실제 메시지

Layer 4: Memory Bank
  └─ 시맨틱 검색으로 top-K 관련 과거 의사결정, 패턴, 해결된 에러를 주입
  └─ 384-dim embeddings, sqlite-vec cosine similarity, FTS hybrid

Layer 3: 훅 주입
  └─ inject-context.sh가 SessionStart 시 세션 연속성 노트, pending self-improve 태스크, top 프로젝트 팩트 주입
  └─ inject-context.sh, self-improve-check.sh, session continuity

Layer 2: Skills / Scaffold
  └─ SKILL.md with NEVER DO 규칙 + 도메인 패턴
  └─ /self-improve 이후 fix 커밋마다 자동 성장
  └─ SKILL.md, frontend-patterns.md, backend-patterns.md

Layer 1: CLAUDE.md (BASE)
  └─ 프로젝트 규칙, 빌드 커맨드, 스택 제약
  └─ 매 세션 영구 기준선으로 상속
```

**Memory Bank Feed**: Layer 3에서 Layer 4로 주입되는 데이터:
- past decisions (과거 의사결정)
- error patterns (에러 패턴)
- project constraints (프로젝트 제약사항)

### FR-3: 훅 시스템 (30개 훅 × 11개 이벤트)

#### 이벤트 유형

| 이벤트 | 설명 | 훅 수 |
|--------|------|-------|
| `PreToolUse` | 도구 실행 전 | 8 |
| `PostToolUse` | 도구 실행 후 | 6 |
| `Notification` | 알림 발생 시 | 3 |
| `Stop` | 세션 종료 시 | 4 |
| `SessionStart` | 세션 시작 시 | 3 |
| `PreCommit` | 커밋 전 | 2 |
| `PostCommit` | 커밋 후 | 1 |
| `BuildSuccess` | 빌드 성공 시 | 1 |
| `BuildFail` | 빌드 실패 시 | 1 |
| `TestFail` | 테스트 실패 시 | 1 |

#### 훅 분류

**HARD 게이트** (차단형, 실패 시 도구 실행 불가):
- 타입 체크 위반 차단
- scaffold NEVER DO 규칙 위반 차단
- 보안 규칙 위반 차단 (비밀번호 하드코딩, wildcard CORS 등)
- 린트 에러 차단

**Agent 훅** (자동 수정형):
- 빌드 실패 시 독립 Opus 에이전트가 에러 분석 + 수정
- 테스트 실패 시 에이전트가 실패 원인 분석 + 수정
- scaffold 위반 시 에이전트가 패턴에 맞게 자동 수정

**SOFT 훅** (가이드형, additionalContext 주입):
- 세션 시작 시 연속성 노트 주입
- 커밋 전 변경 사항 요약 주입
- 에러 발생 시 관련 과거 해결책 주입

### FR-4: Memory Bank 데이터 파이프라인

#### 파이프라인 1: 대화 인덱싱

```
대화 (JSONL files) → 파서 (user/assistant pairs) → Embeddings (384-dim, all-MiniLM-L6-v2)
  → SQLite + vec (exchanges table, vec_exchanges index) → Semantic Search (cosine similarity, FTS hybrid)
```

#### 파이프라인 2: 팩트 추출

```
Session End (stop hook triggers extraction) → Fact Extraction (Haiku LLM, decisions/patterns)
  → 통합 (dedup/contradict/evolve/keep) → Facts DB (2,600+ facts, vec_facts index) → Ontology (domains/categories, INFLUENCES/SUPPORTS)
```

#### Consolidation Relations

| 관계 | 처리 방식 |
|------|-----------|
| **DUPLICATE** | merge into one |
| **CONTRADICTION** | replace old |
| **EVOLUTION** | update + track history |
| **INDEPENDENT** | keep both |

### FR-5: 자가개선 순환 구조 (무한 루프)

```
코드 작성 ({{AI_MODEL}}가 요청 + scaffold 규칙 기반으로 코드 작성)
  → 검증 (30개 hook이 타입, 린트, scaffold 위반 자동 체크)
  → 자동 수정 (Opus agent hook이 독립적으로 에러 수정)
  → 배포 (커밋 + 푸시 + 텔레그램 알림)
  → 학습 (Fix 커밋 감지, 팩트 추출, scaffold 업데이트)
  → 강화 (새 NEVER DO 규칙이 같은 실수를 영원히 방지)
  → 코드 작성 (다시 처음으로 — 무한 루프)
```

### FR-6: 3단계 에스컬레이션

코드에 에러가 있으면 시스템이 자동으로 단계를 올립니다.
3단계까지 사람 개입 불필요.

| 단계 | 이름 | 방식 | 비고 |
|------|------|------|------|
| **1** | 소프트 알림 | additionalContext로 에러 메시지를 {{AI_MODEL}} 컨텍스트에 주입. {{AI_MODEL}}가 보고 수정. | 자동 복구 가능 |
| **2** | 에이전트 수정 | Hook이 독립 Opus 에이전트를 생성. 파일 읽고, 에러 분석, 수정 적용. 메인 스레드와 병렬. | Opus 기반 |
| **3** | 강제 차단 | 도구 실행 차단. 텔레그램 알림. "접근 방식 변경" 메시지. 카운터 리셋. | 사람 개입 필요 |

### FR-7: /team 오케스트레이터 (6역할 × 6 Phase)

기존 3역할(백엔드/프론트엔드/검수) → 6역할로 확장:

| 역할 | Phase 0 (분석) | Phase 1 (설계) | Phase 2 (DB) | Phase 3 (구현) | Phase 4 (QA) | Phase 5 (배포) |
|------|----------------|----------------|--------------|----------------|--------------|----------------|
| **팀 리더** | Orchestrate | Coordinate | Monitor | Coordinate | Review | Ship |
| **설계자** | Brief | 설계 | - | - | - | - |
| **DB 관리자** | - | Schema | Migrate + RLS | - | - | - |
| **프론트엔드** | - | - | Types | UI Components | - | - |
| **백엔드** | - | - | API Spec | API Endpoints | - | - |
| **QA** | - | - | - | - | L0-L5 Tests | - |

**핵심**: 프론트엔드 + 백엔드는 Phase 3에서 **Promise.all()** 병렬 실행.
QA는 구현 완료 후에만 시작.

### FR-8: 워크트리 + WIP 커밋 + 머지 자동화

#### 워크트리 생성
```bash
claude -w  # 자동으로 git worktree 생성, 독립 폴더에서 작업
```

#### 자동 WIP 커밋 (Stop Hook)
세션 종료 시 자동 실행:
1. 현재까지의 변경 사항 감지
2. AI가 작업 내용 + 의사결정 히스토리를 상세히 요약
3. WIP 커밋 자동 생성 (작업 과정 컨텍스트 포함)

#### /merge_worktree 스킬
1. 완료된 워크트리를 메인 브랜치로 스쿼시 머지
2. 지저분한 WIP 커밋들을 하나의 깔끔한 커밋으로 통합
3. 충돌 발생 시 WIP 커밋의 상세 정보를 바탕으로 AI가 자동 해결

---

## 3. 비기능 요구사항 (Non-Functional Requirements)

### NFR-1: 성능
- 훅 실행 시간: 단일 훅 < 3초
- Memory Bank 시맨틱 검색: < 500ms
- 팩트 추출 (Haiku LLM): < 10초/세션
- 컨텍스트 주입 총 시간: < 5초

### NFR-2: 확장성
- 팩트 DB: 10,000+ 팩트까지 검색 성능 유지
- 대화 인덱싱: 100K+ 대화까지 지원
- 훅 수: 100개까지 확장 가능한 구조

### NFR-3: 가용성
- 훅 실패 시 graceful degradation (SOFT 훅은 실패해도 작업 계속)
- Memory Bank 장애 시 CLAUDE.md + Skills로 폴백
- 텔레그램 봇 장애 시 로컬 로그로 폴백

### NFR-4: 보안
- 모든 API 키, {{AUTH_METHOD}} 시크릿은 환경변수 또는 {{ORCHESTRATOR}} Secret으로 관리
- 훅에서 민감 정보 출력 금지
- Memory Bank에 비밀번호/토큰 저장 금지

### NFR-5: 일관성
- Scaffold 패턴 파일은 Git으로 버전 관리
- NEVER DO 규칙 추가 시 기존 코드 소급 적용 검토
- Memory Bank 팩트는 CONTRADICTION 시 이전 버전 기록 유지

---

## 4. 제약사항 및 예상 규모

### 개발 환경
- **플랫폼**: Windows 11 + Git Bash
- **Claude Code**: Opus 4.6 (1M context)
- **Git**: 워크트리 지원 필수
- **Node.js**: 20+ (프론트엔드 빌드)
- **{{BACKEND_FRAMEWORK}}**: 8.0 (백엔드 빌드)

### 예상 규모
- **팩트 DB 크기**: ~50MB (10,000 팩트 기준)
- **임베딩 벡터**: 384-dim × 10,000 = ~15MB
- **대화 인덱싱**: 50K 대화 × 평균 2KB = ~100MB
- **총 로컬 스토리지**: ~200MB

### 읽기/쓰기 비율
- **팩트 DB**: 읽기:쓰기 = 50:1 (세션당 다수 읽기, 종료 시 1회 쓰기)
- **대화 인덱싱**: 읽기:쓰기 = 10:1

### 기술 스택 제약
- **임베딩 모델**: all-MiniLM-L6-v2 (384-dim) — 로컬 실행 또는 임베딩 서버
- **벡터 DB**: SQLite + sqlite-vec (외부 서비스 의존 없음)
- **LLM (팩트 추출)**: {{AI_MODEL}} Haiku 4.5 (비용 효율)
- **텔레그램 봇**: 기존 인프라 활용 또는 신규 생성

---

## 5. 구현 우선순위 (Phase 계획)

### Phase 1: 기반 구축 (Foundation)
1. CLAUDE.md 강화 (빌드 커맨드, 스택 제약 명시)
2. Scaffold 패턴 파일 생성 (frontend-patterns.md, backend-patterns.md)
3. NEVER DO 규칙 통합 문서 생성
4. 기본 훅 구조 설정 (settings.json hooks 설정)

### Phase 2: 훅 시스템 (Guard Rails)
1. HARD 게이트 훅 (타입체크, 린트, 보안)
2. SOFT 훅 (컨텍스트 주입)
3. Agent 훅 (자동 수정)
4. 훅 테스트 및 검증

### Phase 3: Memory Bank (Knowledge)
1. SQLite + sqlite-vec 설정
2. 대화 파서 + 임베딩 파이프라인
3. 팩트 추출 파이프라인
4. 시맨틱 검색 API
5. inject-context.sh 연동

### Phase 4: 자가개선 루프 (Intelligence)
1. Fix 커밋 감지 → 팩트 자동 추출
2. scaffold 자동 업데이트
3. NEVER DO 자동 추가
4. self-improve 태스크 관리

### Phase 5: /team 오케스트레이터 확장 (Scale)
1. 6역할 정의 및 SKILL.md 업데이트
2. Phase 0~5 실행 흐름 구현
3. Promise.all() 병렬 실행
4. QA L0-L5 테스트 스킬

### Phase 6: 에스컬레이션 + 워크트리 (Resilience)
1. 3단계 에스컬레이션 구현
2. 텔레그램 알림 연동
3. 워크트리 자동 생성/정리
4. WIP 커밋 + /merge_worktree 스킬

---

## 6. 성공 지표 (KPI)

| 지표 | 측정 방법 | 목표 |
|------|-----------|------|
| 자동 에러 수정률 | (자동 수정된 에러 / 전체 에러) × 100 | > 80% |
| 사람 개입 빈도 | 3단계 에스컬레이션 발생 횟수 / 전체 세션 | < 5% |
| scaffold 위반 재발률 | (같은 패턴 위반 재발 / 최초 위반) × 100 | < 10% |
| 빌드 성공률 | (최초 빌드 성공 / 전체 빌드 시도) × 100 | > 90% |
| 배포 성공률 | (최초 배포 성공 / 전체 배포 시도) × 100 | > 95% |

---

## 관련 문서
- [5-Layer Architecture](./architecture-5layer.md) - 아키텍처 상세
- [Hook System](./hook-system.md) - 훅 시스템 상세
- [Memory Bank](./memory-bank.md) - 메모리 뱅크 상세
- [Self-Improvement Loop](./self-improvement-loop.md) - 자가개선 루프
- [시스템 아키텍처](../architecture.md) - 서비스 인프라

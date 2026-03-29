# 프롬프트 컨텍스트 스택 (Context Assembly)

## 개요

모든 {{AI_MODEL}} 프롬프트는 이미 풍부한 컨텍스트 위에서 실행됩니다.
사용자의 메시지는 깊은 스택의 가장 위에 도착하는 것입니다.

---

## 5-Layer 스택 구조

```
┌─────────────────────────────────────────────────┐
│  5  사용자 프롬프트                         TOP  │
│     사용자가 타이핑한 실제 메시지                 │
│     이미 풍부한 컨텍스트 윈도우의 맨 위에 도착    │
├─────────────────────────────────────────────────┤
│  4  Memory Bank                    ← feeds context │
│     시맨틱 검색으로 top-K 관련 과거 의사결정,     │
│     패턴, 해결된 에러 2,600+ 팩트에서 주입        │
│     384-dim embeddings | sqlite-vec cosine       │
│     similarity | FTS hybrid                      │
├─────────────────────────────────────────────────┤
│  3  훅 주입                        ← auto-injected │
│     inject-context.sh가 SessionStart 시 실행     │
│     - 세션 연속성 노트                            │
│     - pending self-improve 태스크                │
│     - top 프로젝트 팩트                           │
│     inject-context.sh | self-improve-check.sh   │
│     | session continuity                         │
├─────────────────────────────────────────────────┤
│  2  Skills / Scaffold              ← loaded at start │
│     SKILL.md with NEVER DO 규칙 + 도메인 패턴    │
│     /self-improve 이후 fix 커밋마다 자동 성장     │
│     SKILL.md | frontend-patterns.md             │
│     | backend-patterns.md                        │
├─────────────────────────────────────────────────┤
│  1  CLAUDE.md                           BASE    │
│     프로젝트 규칙, 빌드 커맨드, 스택 제약         │
│     매 세션 영구 기준선으로 상속                   │
│     project rules | build commands | stack config│
└─────────────────────────────────────────────────┘
```

---

## 각 레이어 상세

### Layer 1: CLAUDE.md (BASE)

**로딩 시점**: 매 세션 시작 시 자동 (Claude Code 내장)

**포함 내용**:
- 프로젝트 개요 및 역할 정의
- 빌드 커맨드 (`{{BACKEND_FRAMEWORK}} build`, `npm run build`)
- 기술 스택 제약 ({{FRONTEND_FRAMEWORK}} App Router, C# {{BACKEND_FRAMEWORK}})
- 스킬/커맨드 목록 및 사용법
- 개발 워크플로우 규칙
- 문서 참조 경로

**현재 상태 → 개선 방향**:
```
현재: 개요 + 도구 설명 위주
개선: + 빌드/테스트 커맨드 명시
     + NEVER DO 규칙 inline 요약
     + scaffold 패턴 파일 참조
     + Memory Bank 사용법 안내
```

### Layer 2: Skills / Scaffold

**로딩 시점**: 세션 시작 시 자동 (`.claude/skills/` 디렉토리)

**구조**:
```
.claude/skills/
├── frontend-patterns.md      # 프론트엔드 코딩 패턴 + NEVER DO
├── backend-patterns.md       # 백엔드 코딩 패턴 + NEVER DO
├── never-do.md               # 통합 NEVER DO 규칙 목록
├── agent-teams/SKILL.md      # 팀 오케스트레이터
├── dev-cycle/SKILL.md        # 개발 사이클 자동화
├── deploy/SKILL.md           # 배포
├── qa-test/SKILL.md          # QA 테스트
├── color-picker.md           # 컬러 피커 규칙
├── secure-web-saas.md        # 보안 규칙
├── system-design-validator.md # 설계 검증
├── self-improve/SKILL.md     # 자가개선 스킬 (신규)
├── scaffold-update/SKILL.md  # scaffold 업데이트 (신규)
└── merge-worktree/SKILL.md   # 워크트리 머지 (신규)
```

**자동 성장 메커니즘**:
```
Fix 커밋 감지
  → 팩트 추출 (어떤 패턴이 문제였는지)
  → /self-improve 스킬 실행
  → scaffold 파일에 새 NEVER DO 규칙 추가
  → 다음 세션부터 Layer 2에 자동 반영
```

### Layer 3: 훅 주입

**로딩 시점**: SessionStart 이벤트 시 자동 (inject-context.sh)

**주입 데이터**:

| 데이터 | 소스 | 목적 |
|--------|------|------|
| 세션 연속성 노트 | 이전 세션의 WIP 커밋 메시지 | 작업 이어가기 |
| self-improve 태스크 | pending 상태의 개선 제안 | 미완료 개선 적용 |
| top 프로젝트 팩트 | Memory Bank top-5 | 핵심 제약사항 상기 |

**inject-context.sh 의사코드**:
```bash
#!/bin/bash
# SessionStart 훅

# 1. 세션 연속성 노트 로드
LAST_WIP=$(git log --oneline -1 --format="%s %b" 2>/dev/null | head -5)

# 2. pending self-improve 태스크 확인
PENDING=$(sqlite3 memory.db "SELECT fact FROM facts WHERE type='self-improve' AND status='pending' LIMIT 3")

# 3. top 프로젝트 팩트
TOP_FACTS=$(sqlite3 memory.db "SELECT fact FROM facts ORDER BY relevance DESC LIMIT 5")

# additionalContext로 주입
cat <<EOF
## Session Context (Auto-injected)

### Last Session
$LAST_WIP

### Pending Improvements
$PENDING

### Key Project Facts
$TOP_FACTS
EOF
```

### Layer 4: Memory Bank

**로딩 시점**: Layer 3 inject-context.sh가 호출 + 세션 중 실시간 검색

**Memory Bank Feed → Layer 3 주입 데이터**:
- **past decisions**: 과거에 특정 기술 선택을 한 이유
- **error patterns**: 반복되는 에러와 해결 방법
- **project constraints**: 프로젝트의 불변 제약사항

**실시간 검색 흐름**:
```
사용자: "채팅 기능 수정해줘"
  → Memory Bank에 "채팅" 관련 top-K 팩트 검색
  → 관련 과거 의사결정 + 에러 패턴 + 제약사항 주입
  → {{AI_MODEL}}가 풍부한 컨텍스트로 작업 시작
```

### Layer 5: 사용자 프롬프트

**로딩 시점**: 사용자가 메시지를 전송할 때

사용자의 실제 메시지. Layer 1~4의 풍부한 컨텍스트 위에 도착합니다.
사용자는 짧은 지시만으로도 시스템이 전체 맥락을 파악하고 실행할 수 있습니다.

---

## 컨텍스트 로딩 타임라인

```
세션 시작
  │
  ├─ t=0s:    Layer 1 (CLAUDE.md) 로딩 — 자동
  ├─ t=0s:    Layer 2 (Skills/Scaffold) 로딩 — 자동
  ├─ t=1~3s:  Layer 3 (inject-context.sh) 실행 — SessionStart 훅
  ├─ t=2~5s:  Layer 4 (Memory Bank) top 팩트 주입 — Layer 3이 호출
  │
  └─ t=?:     Layer 5 (사용자 프롬프트) 도착
              → 이미 L1~L4의 컨텍스트가 준비된 상태에서 작업 시작
```

---

## 관련 문서
- [5-Layer Architecture](./architecture-5layer.md) - 레이어 아키텍처
- [Hook System](./hook-system.md) - 훅 시스템 상세
- [Memory Bank](./memory-bank.md) - 메모리 뱅크 상세
- [PRD](./prd.md) - 전체 요구사항

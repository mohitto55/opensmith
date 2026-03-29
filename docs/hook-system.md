# 훅 시스템 (30개 훅 × 11개 이벤트)

## 개요

훅은 Claude Code의 도구 실행 전후에 자동으로 실행되는 스크립트입니다.
LoopyEra에서 훅은 **자동 품질 보증 + 자가 수정 + 컨텍스트 강화**의 핵심 메커니즘입니다.

---

## 이벤트 유형 (11종)

| # | 이벤트 | 트리거 시점 | 주요 용도 |
|---|--------|-----------|-----------|
| 1 | `PreToolUse` | 도구 실행 전 | HARD 게이트 차단 |
| 2 | `PostToolUse` | 도구 실행 후 | 결과 검증 + 자동 수정 |
| 3 | `Notification` | 알림 발생 시 | 에스컬레이션 라우팅 |
| 4 | `Stop` | 세션 종료 시 | WIP 커밋 + 팩트 추출 |
| 5 | `SessionStart` | 세션 시작 시 | 컨텍스트 주입 |
| 6 | `PreCommit` | 커밋 전 | 코드 품질 최종 체크 |
| 7 | `PostCommit` | 커밋 후 | 팩트 추출 트리거 |
| 8 | `BuildSuccess` | 빌드 성공 시 | 성공 메트릭 기록 |
| 9 | `BuildFail` | 빌드 실패 시 | 에이전트 수정 트리거 |
| 10 | `TestFail` | 테스트 실패 시 | 에이전트 수정 트리거 |
| 11 | `SubagentStop` | 서브에이전트 종료 시 | 결과 수집 + 다음 단계 트리거 |

---

## 훅 분류 체계

### HARD 게이트 (차단형) — 8개

실패 시 도구 실행을 **차단**합니다. 코드 품질의 최후 방어선.

| # | 훅 이름 | 이벤트 | 동작 |
|---|--------|--------|------|
| H1 | `typecheck-gate` | PreToolUse(Write/Edit) | TypeScript/C# 파일 수정 시 `tsc --noEmit` / `{{BACKEND_FRAMEWORK}} build` 실행. 타입 에러 있으면 차단 |
| H2 | `lint-gate` | PreToolUse(Write/Edit) | ESLint/StyleCop 실행. 에러 수준 린트 위반 시 차단 |
| H3 | `scaffold-never-do` | PreToolUse(Write/Edit) | 변경 내용이 NEVER DO 규칙 위반인지 패턴 매칭. 위반 시 차단 |
| H4 | `security-gate` | PreToolUse(Write/Edit) | 하드코딩 비밀번호, wildcard CORS, MD5 해싱 등 보안 위반 감지. 차단 |
| H5 | `import-guard` | PreToolUse(Write/Edit) | 금지된 라이브러리 import 감지 (예: `react-color` 대신 `react-colorful`) |
| H6 | `file-size-guard` | PreToolUse(Write) | 단일 파일 500줄 초과 시 경고 + 800줄 초과 시 차단 |
| H7 | `test-coverage-gate` | PreCommit | 새 기능 코드에 대응하는 테스트 파일이 존재하지 않으면 차단 |
| H8 | `docs-structure-gate` | PreCommit | docs/ 변경 시 필수 섹션 검증 (기존 validate-docs.sh 통합) |

### Agent 훅 (자동 수정형) — 6개

에러 발생 시 **독립 Opus 에이전트**를 스폰하여 자동 수정을 시도합니다.

| # | 훅 이름 | 이벤트 | 동작 |
|---|--------|--------|------|
| A1 | `build-fix-agent` | BuildFail | 빌드 에러 로그를 읽고, 관련 파일을 분석하여 자동 수정. 메인 스레드와 병렬 실행 |
| A2 | `test-fix-agent` | TestFail | 실패한 테스트의 에러 메시지와 테스트 코드를 분석. 구현 코드 또는 테스트 코드를 수정 |
| A3 | `scaffold-fix-agent` | PostToolUse(Write/Edit) | scaffold 위반이 감지되면 패턴에 맞게 코드를 자동 재작성 |
| A4 | `type-fix-agent` | PostToolUse(Write/Edit) | 타입 에러 발생 시 타입 정의를 분석하고 올바른 타입으로 수정 |
| A5 | `deploy-fix-agent` | PostToolUse(Bash:{{ORCHESTRATOR}}) | {{ORCHESTRATOR}} 배포 실패 시 Pod 로그 분석 + 매니페스트 수정 |
| A6 | `merge-conflict-agent` | PostToolUse(Bash:git merge) | 머지 충돌 시 WIP 커밋 히스토리를 기반으로 자동 해결 |

### SOFT 훅 (가이드형) — 16개

**additionalContext**로 정보를 주입합니다. 실패해도 작업을 중단하지 않습니다.

| # | 훅 이름 | 이벤트 | 동작 |
|---|--------|--------|------|
| S1 | `inject-context` | SessionStart | 세션 연속성 노트 + pending self-improve + top 팩트 주입 |
| S2 | `self-improve-check` | SessionStart | 미완료 self-improve 태스크가 있으면 알림 |
| S3 | `session-continuity` | SessionStart | 마지막 WIP 커밋 메시지로 이전 작업 컨텍스트 복원 |
| S4 | `change-summary` | PreCommit | 변경 사항을 자동 요약하여 커밋 메시지에 컨텍스트 제공 |
| S5 | `error-pattern-warn` | PostToolUse(Bash) | 에러 메시지가 Memory Bank의 기존 패턴과 매치되면 해결책 주입 |
| S6 | `api-consistency` | PostToolUse(Write/Edit) | API 엔드포인트 변경 시 기존 API 패턴과의 일관성 경고 |
| S7 | `component-pattern` | PostToolUse(Write/Edit) | React 컴포넌트 작성 시 기존 컴포넌트 패턴 가이드 주입 |
| S8 | `db-schema-warn` | PostToolUse(Write/Edit) | {{DATABASE}} 스키마 변경 시 관련 서비스 영향 범위 알림 |
| S9 | `deploy-checklist` | PreToolUse(Bash:{{ORCHESTRATOR}}) | 배포 전 체크리스트 자동 주입 |
| S10 | `perf-hint` | PostToolUse(Write/Edit) | N+1 쿼리, 불필요한 리렌더 등 성능 안티패턴 감지 시 가이드 |
| S11 | `dependency-alert` | PostToolUse(Bash:npm install) | 새 패키지 추가 시 번들 크기 영향 + 대안 제안 |
| S12 | `worktree-status` | SessionStart | 현재 활성 워크트리 목록 + 각 워크트리의 마지막 작업 상태 |
| S13 | `fact-extraction` | Stop | 세션 종료 시 대화에서 팩트 자동 추출 |
| S14 | `wip-commit` | Stop | 미커밋 변경 사항이 있으면 WIP 커밋 자동 생성 |
| S15 | `metrics-log` | Stop | 세션 메트릭 기록 (빌드 횟수, 에러 수, 수정 횟수) |
| S16 | `telegram-notify` | Notification(escalation=3) | 3단계 에스컬레이션 시 텔레그램으로 알림 |

---

## settings.json 훅 설정 구조

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "bash .claude/hooks/hard/typecheck-gate.sh $FILE",
        "type": "intercept"
      },
      {
        "matcher": "Write|Edit",
        "command": "bash .claude/hooks/hard/scaffold-never-do.sh $FILE",
        "type": "intercept"
      },
      {
        "matcher": "Write|Edit",
        "command": "bash .claude/hooks/hard/security-gate.sh $FILE",
        "type": "intercept"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "bash .claude/hooks/soft/error-pattern-warn.sh $FILE",
        "type": "additionalContext"
      },
      {
        "matcher": "Bash",
        "command": "bash .claude/hooks/agent/build-fix-agent.sh",
        "type": "agent",
        "onFailure": "escalate"
      }
    ],
    "Stop": [
      {
        "command": "bash .claude/hooks/soft/wip-commit.sh",
        "type": "additionalContext"
      },
      {
        "command": "bash .claude/hooks/soft/fact-extraction.sh",
        "type": "additionalContext"
      }
    ],
    "SessionStart": [
      {
        "command": "bash .claude/hooks/soft/inject-context.sh",
        "type": "additionalContext"
      }
    ]
  }
}
```

---

## 훅 파일 구조

```
.claude/hooks/
├── hard/                        # HARD 게이트 (차단형)
│   ├── typecheck-gate.sh        # H1: 타입 체크
│   ├── lint-gate.sh             # H2: 린트 체크
│   ├── scaffold-never-do.sh     # H3: NEVER DO 위반
│   ├── security-gate.sh         # H4: 보안 위반
│   ├── import-guard.sh          # H5: 금지 라이브러리
│   ├── file-size-guard.sh       # H6: 파일 크기
│   ├── test-coverage-gate.sh    # H7: 테스트 커버리지
│   └── docs-structure-gate.sh   # H8: 문서 구조 (기존 validate-docs.sh 통합)
├── agent/                       # Agent 훅 (자동 수정형)
│   ├── build-fix-agent.sh       # A1: 빌드 실패 자동 수정
│   ├── test-fix-agent.sh        # A2: 테스트 실패 자동 수정
│   ├── scaffold-fix-agent.sh    # A3: scaffold 위반 자동 수정
│   ├── type-fix-agent.sh        # A4: 타입 에러 자동 수정
│   ├── deploy-fix-agent.sh      # A5: 배포 실패 자동 수정
│   └── merge-conflict-agent.sh  # A6: 머지 충돌 자동 해결
├── soft/                        # SOFT 훅 (가이드형)
│   ├── inject-context.sh        # S1: 컨텍스트 주입
│   ├── self-improve-check.sh    # S2: self-improve 체크
│   ├── session-continuity.sh    # S3: 세션 연속성
│   ├── change-summary.sh        # S4: 변경 요약
│   ├── error-pattern-warn.sh    # S5: 에러 패턴 경고
│   ├── api-consistency.sh       # S6: API 일관성
│   ├── component-pattern.sh     # S7: 컴포넌트 패턴
│   ├── db-schema-warn.sh        # S8: DB 스키마 경고
│   ├── deploy-checklist.sh      # S9: 배포 체크리스트
│   ├── perf-hint.sh             # S10: 성능 힌트
│   ├── dependency-alert.sh      # S11: 의존성 경고
│   ├── worktree-status.sh       # S12: 워크트리 상태
│   ├── fact-extraction.sh       # S13: 팩트 추출
│   ├── wip-commit.sh            # S14: WIP 커밋
│   ├── metrics-log.sh           # S15: 메트릭 로그
│   └── telegram-notify.sh       # S16: 텔레그램 알림
└── lib/                         # 공통 라이브러리
    ├── escalation.sh            # 에스컬레이션 카운터 관리
    ├── memory-query.sh          # Memory Bank 쿼리 헬퍼
    └── patterns.sh              # NEVER DO 패턴 로더
```

---

## 에스컬레이션 연동

훅 실패 시 에스컬레이션 시스템과 연동:

```
HARD 게이트 실패
  → 에스컬레이션 카운터 +1
  → 카운터 < 3: 1단계 (소프트 알림 → {{AI_MODEL}}가 자동 수정)
  → 카운터 = 3: 2단계 (Agent 훅이 독립 에이전트 스폰)
  → 카운터 > 5: 3단계 (도구 차단 + 텔레그램 알림)
```

→ 상세: [Escalation System](./escalation-system.md)

---

## 관련 문서
- [PRD](./prd.md) - 전체 요구사항
- [5-Layer Architecture](./architecture-5layer.md) - 레이어 아키텍처
- [Escalation System](./escalation-system.md) - 에스컬레이션 상세
- [Context Stack](./context-stack.md) - 컨텍스트 스택

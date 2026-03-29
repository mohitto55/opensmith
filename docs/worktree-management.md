# 워크트리 + WIP 커밋 + 머지 자동화

## 개요

Git 워크트리를 활용하여 여러 기능을 동시에 개발하되, 컨텍스트를 잃지 않도록
자동 WIP 커밋과 스마트 머지를 지원합니다.

---

## 1. Git 워크트리 (Worktree)

### 일반 브랜치 vs 워크트리

| | 일반 브랜치 | 워크트리 |
|---|-----------|---------|
| 폴더 | 하나의 폴더에서 소스 상태만 변경 | 각 브랜치별 독립 물리 폴더 |
| 동시 작업 | 불가 (체크아웃 전환 필요) | 가능 (각 폴더에서 독립 실행) |
| 메인 브랜치 오염 | 가능성 있음 | 없음 (물리적 분리) |
| Claude Code 지원 | 기본 | `-w` 옵션으로 자동 생성 |

### 워크트리 생성

```bash
# Claude Code에서 워크트리 모드로 실행
claude -w

# 또는 수동 생성
git worktree add ../{{PROJECT_NAME}}-feature-chat feature/chat
git worktree add ../{{PROJECT_NAME}}-feature-shop feature/shop
```

### 워크트리 목록 확인

```bash
git worktree list
# C:/Users/admin/git/{{PROJECT_NAME}}           780216d [main]
# C:/Users/admin/git/{{PROJECT_NAME}}-feature-chat  abc1234 [feature/chat]
# C:/Users/admin/git/{{PROJECT_NAME}}-feature-shop  def5678 [feature/shop]
```

### 워크트리 구조

```
C:/Users/admin/git/
├── {{PROJECT_NAME}}/                    # 메인 워크트리 (main 브랜치)
├── {{PROJECT_NAME}}-feature-chat/       # 워크트리 1 (feature/chat 브랜치)
├── {{PROJECT_NAME}}-feature-shop/       # 워크트리 2 (feature/shop 브랜치)
└── {{PROJECT_NAME}}-feature-stats/      # 워크트리 3 (feature/stats 브랜치)
```

---

## 2. 자동 WIP 커밋 (Stop Hook)

### 트리거

세션 종료 시 `Stop` 이벤트 → `wip-commit.sh` 훅 실행

### 동작 흐름

```
세션 종료 (Stop 이벤트)
    │
    ▼
┌─ wip-commit.sh ──────────────────────────────┐
│                                               │
│  1. 미커밋 변경 사항 있는지 확인               │
│     git status --porcelain                    │
│                                               │
│  2. 변경 사항 있으면:                          │
│     a. 변경된 파일 목록 수집                   │
│     b. diff 요약 생성                          │
│     c. AI가 작업 내용 + 의사결정 히스토리 요약  │
│     d. WIP 커밋 생성                           │
│                                               │
│  3. 변경 사항 없으면:                          │
│     → 아무것도 하지 않음                       │
└───────────────────────────────────────────────┘
```

### WIP 커밋 메시지 형식

```
WIP: [작업 요약 한 줄]

## 작업 내용
- [수정한 파일 1]: [변경 내용]
- [수정한 파일 2]: [변경 내용]

## 의사결정 기록
- [결정 1]: [이유] → [선택한 방법]
- [결정 2]: [이유] → [선택한 방법]

## 미완료 항목
- [ ] [남은 작업 1]
- [ ] [남은 작업 2]

## 컨텍스트
- 이전 세션 참조: [관련 커밋 해시]
- 다음 세션에서: [이어서 할 작업]
```

### WIP 커밋의 가치

단순히 코드만 저장하는 것이 아니라 **의사결정 히스토리**를 기록합니다:
- 왜 A 방식 대신 B 방식을 선택했는지
- 어떤 시도가 실패했고 왜
- 다음 세션에서 무엇을 이어서 해야 하는지

이 정보는:
1. 다음 세션 시작 시 **session-continuity** 훅이 컨텍스트를 복원하는 데 사용
2. 머지 충돌 시 **merge-conflict-agent**가 올바른 변경을 선택하는 근거
3. **Memory Bank** 팩트 추출의 소스

### wip-commit.sh 스크립트

```bash
#!/bin/bash
# .claude/hooks/soft/wip-commit.sh
# Stop 훅: 세션 종료 시 자동 WIP 커밋

set -e

# 1. 변경 사항 확인
CHANGES=$(git status --porcelain 2>/dev/null)
if [ -z "$CHANGES" ]; then
  exit 0  # 변경 없음
fi

# 2. 변경된 파일 목록
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null)
UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null)

# 3. diff 요약 (최대 500줄)
DIFF_SUMMARY=$(git diff --stat HEAD 2>/dev/null | tail -20)

# 4. WIP 커밋 메시지 생성 ({{AI_MODEL}} Haiku로 요약)
# 실제 구현에서는 claude CLI 또는 API 호출
WIP_MSG="WIP: $(date +%Y-%m-%d) session work

## Changed Files
$CHANGED_FILES

## Diff Summary
$DIFF_SUMMARY

## Untracked
$UNTRACKED
"

# 5. 모든 변경 사항 스테이징 + 커밋
git add -A
git commit -m "$WIP_MSG" --no-verify

echo "WIP 커밋 생성 완료"
```

---

## 3. /merge_worktree 스킬

### 역할

완료된 워크트리를 메인 브랜치로 **스쿼시 머지**합니다.

### 실행 흐름

```
/merge_worktree feature/chat

    │
    ▼
┌─────────────────────────────────────────────┐
│  1. 워크트리 상태 확인                       │
│     - 미커밋 변경 있으면 WIP 커밋 먼저 생성   │
│     - 브랜치 이름과 커밋 히스토리 확인         │
│                                             │
│  2. 스쿼시 머지 준비                         │
│     - main 브랜치로 이동                     │
│     - git merge --squash feature/chat       │
│                                             │
│  3. 충돌 처리 (있는 경우)                    │
│     - WIP 커밋들의 의사결정 히스토리 분석     │
│     - AI가 어떤 변경을 우선할지 판단          │
│     - 자동 충돌 해결                         │
│                                             │
│  4. 스쿼시 커밋 생성                         │
│     - 모든 WIP 커밋의 내용을 종합하여         │
│     - 하나의 깔끔한 커밋 메시지 생성          │
│                                             │
│  5. 워크트리 정리                            │
│     - git worktree remove                   │
│     - 브랜치 삭제 (선택적)                   │
└─────────────────────────────────────────────┘
```

### 스쿼시 커밋 메시지 형식

```
feat: [기능 요약]

## 구현 내용
- [주요 변경 1]
- [주요 변경 2]
- [주요 변경 3]

## 기술 결정
- [결정 1]: [선택한 방법과 이유]

## 테스트
- [테스트 결과 요약]

Squashed from branch: feature/chat (N commits)
```

### 충돌 자동 해결

WIP 커밋에 기록된 의사결정 히스토리를 활용:

```
충돌 파일: frontend/app/components/Header.tsx

워크트리 A (feature/chat)의 WIP 히스토리:
  "Header에 채팅 알림 배지 추가. 기존 프로필 드롭다운 우측에 배치."

워크트리 B (main)의 최신 변경:
  "Header 레이아웃 수정. flex → grid로 전환."

→ AI 판단: 두 변경 모두 유지.
  grid 레이아웃 안에 채팅 알림 배지를 배치하도록 병합.
```

---

## 4. 워크트리 관리 훅

### S12: worktree-status (SessionStart)

세션 시작 시 활성 워크트리 상태를 표시:

```
## Active Worktrees

| 브랜치 | 경로 | 마지막 커밋 | 상태 |
|--------|------|-----------|------|
| main | C:/Users/admin/git/{{PROJECT_NAME}} | 780216d (2h ago) | clean |
| feature/chat | .../{{PROJECT_NAME}}-feature-chat | abc1234 WIP (30m ago) | 3 modified |
| feature/shop | .../{{PROJECT_NAME}}-feature-shop | def5678 WIP (1d ago) | clean |
```

---

## 5. 병렬 작업 시나리오

### 시나리오: 채팅 기능 + 상점 기능 동시 개발

```
# 터미널 1: 채팅 기능
cd C:/Users/admin/git/{{PROJECT_NAME}}-feature-chat
claude  # 이 워크트리에서 작업

# 터미널 2: 상점 기능
cd C:/Users/admin/git/{{PROJECT_NAME}}-feature-shop
claude  # 이 워크트리에서 독립 작업

# 세션 종료 시 각 워크트리에 WIP 커밋 자동 생성

# 채팅 기능 완료 시
claude /merge_worktree feature/chat  # main으로 스쿼시 머지

# 상점 기능 완료 시
claude /merge_worktree feature/shop  # main으로 스쿼시 머지
```

---

## 관련 문서
- [PRD](./prd.md) - 전체 요구사항
- [Hook System](./hook-system.md) - 훅 시스템 (Stop 훅)
- [Self-Improvement Loop](./self-improvement-loop.md) - 자가개선 루프
- [5-Layer Architecture](./architecture-5layer.md) - 레이어 아키텍처

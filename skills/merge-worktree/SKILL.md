---
name: merge-worktree
description: "완료된 워크트리를 메인 브랜치로 스쿼시 머지. '/merge_worktree', '워크트리 머지', 'worktree merge' 등을 요청할 때 사용."
allowed-tools: Bash(git *), Read, Glob, Grep
argument-hint: "<브랜치명 또는 워크트리 경로>"
---

# /merge_worktree — 워크트리 스쿼시 머지

## 실행 절차

대상 브랜치: `$ARGUMENTS`

### Step 1: 상태 확인

```bash
# 현재 워크트리 목록
git worktree list

# 대상 브랜치 확인
git log --oneline -10 $ARGUMENTS

# 미커밋 변경 확인
cd <worktree_path> && git status --porcelain
```

미커밋 변경이 있으면 WIP 커밋 먼저 생성.

### Step 2: 메인 브랜치로 이동

```bash
cd <main_worktree_path>
git checkout main
git pull origin main  # 최신 상태 동기화
```

### Step 3: 스쿼시 머지

```bash
git merge --squash $ARGUMENTS
```

### Step 4: 충돌 처리 (있는 경우)

충돌 발생 시:
1. 충돌 파일 목록 확인: `git diff --name-only --diff-filter=U`
2. 대상 브랜치의 WIP 커밋 히스토리 분석:
   ```bash
   git log --format="%h %s%n%b" $ARGUMENTS | grep -A5 "WIP:"
   ```
3. WIP 커밋의 의사결정 기록을 참고하여 충돌 해결
4. 해결 후 `git add <파일>`

### Step 5: 스쿼시 커밋 생성

WIP 커밋들의 내용을 종합하여 하나의 깔끔한 커밋 메시지 생성:

```bash
# WIP 히스토리에서 커밋 메시지 수집
WIP_MESSAGES=$(git log --format="%B" main..$ARGUMENTS | head -100)

# 종합 커밋 메시지 작성
git commit -m "feat: [기능 요약]

## 구현 내용
- [변경 1]
- [변경 2]

Squashed from branch: $ARGUMENTS
"
```

### Step 6: 워크트리 정리

```bash
# 워크트리 제거
git worktree remove <worktree_path>

# 브랜치 삭제 (선택적 — 사용자에게 확인)
git branch -d $ARGUMENTS
```

### Step 7: 결과 보고

| 항목 | 결과 |
|------|------|
| 소스 브랜치 | $ARGUMENTS |
| 커밋 수 (스쿼시 전) | N |
| 충돌 파일 | M개 |
| 최종 커밋 | [해시] |
| 워크트리 정리 | 완료/보류 |

## 주의사항

- 스쿼시 머지 전 반드시 main 브랜치를 최신 상태로 동기화
- 충돌 해결 시 WIP 커밋의 의사결정 기록을 우선 참고
- 워크트리 삭제 전 사용자 확인
- --force 사용 금지

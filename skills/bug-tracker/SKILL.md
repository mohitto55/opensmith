---
name: bug-tracker
description: "버그 수집/추적 스킬. 발견된 버그를 .opensmith/bugs.json에 기록하고, 미해결 버그 목록을 관리. 'bug', '버그', '이슈 추가', '버그 목록' 등을 요청할 때 사용."
allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep
argument-hint: "<add|list|fix|report> [버그 설명]"
---

# /bug-tracker — 버그 수집 및 추적

발견된 버그를 `.opensmith/bugs.json`에 중앙 집중 기록하고 추적합니다.
execute 파이프라인 안팎 모두에서 사용 가능합니다.

## 명령어

### add — 버그 등록

```
/opensmith:bug-tracker add 뒤로가기 버튼이 잠금 화면을 우회함
```

`.opensmith/bugs.json`에 추가:

```json
{
  "id": "BUG-001",
  "description": "뒤로가기 버튼이 잠금 화면을 우회함",
  "severity": "high",
  "status": "open",
  "found_at": "2026-03-29T12:00:00",
  "found_by": "qa",
  "feature": "[현재 작업 중인 기능 또는 null]",
  "file": "[관련 파일 경로 또는 null]",
  "line": null,
  "resolved_at": null,
  "fix_commit": null
}
```

**severity 자동 판정:**
- `critical`: 데이터 손실, 보안 취약점, 앱 크래시
- `high`: 핵심 기능 동작 안 함, UI 우회
- `medium`: 비핵심 기능 오류, UI 깨짐
- `low`: 오타, 미세 정렬, 개선 사항

**여러 버그 한 번에 등록:**

테이블 형태로 발견된 버그 목록이 있으면 자동으로 파싱하여 전부 등록합니다.

### list — 버그 목록 조회

```
/opensmith:bug-tracker list            # 전체 (open만)
/opensmith:bug-tracker list all        # 전체 (fixed 포함)
/opensmith:bug-tracker list critical   # severity별
/opensmith:bug-tracker list F-1        # 기능별
```

출력:
```
미해결 버그: N개

| ID | Severity | 설명 | 기능 | 파일 |
|----|----------|------|------|------|
| BUG-001 | high | 뒤로가기 버튼 우회 | F-1 | LockOverlayActivity.kt |
| BUG-003 | medium | 중앙 정렬 안 됨 | F-1 | HomeScreen.kt |
```

### fix — 버그 해결 처리

```
/opensmith:bug-tracker fix BUG-001
```

- bugs.json에서 해당 버그 status를 "fixed"로 변경
- resolved_at에 현재 시간 기록
- fix_commit에 최근 커밋 해시 기록

### report — 버그 리포트 생성

```
/opensmith:bug-tracker report
```

`.opensmith/bug-report.md` 생성:

```markdown
# Bug Report — [프로젝트명]
> 생성일: YYYY-MM-DD

## 요약
- 전체: N개
- Open: N개 (critical: N, high: N, medium: N, low: N)
- Fixed: N개

## 미해결 버그
| ID | Severity | 설명 | 기능 | 발견일 |
...

## 해결된 버그
| ID | Severity | 설명 | 해결일 | 커밋 |
...
```

## 자동 연동

### execute 파이프라인과 연동

step7(QA)에서 버그 발견 시 **자동으로 bugs.json에 기록**됩니다.

### step0에서 미해결 버그 확인

execute 시작 시 bugs.json의 critical/high 버그가 있으면 경고:
```
미해결 critical/high 버그 N개가 있습니다.
새 기능 개발 전에 해결을 권장합니다.
```

### Memory Bank 연동

버그 패턴이 반복되면 Memory Bank에 fact로 기록:
- type: "error"
- fact: "[반복 버그 패턴 설명]"

## bugs.json 위치

`.opensmith/bugs.json` — 프로젝트 루트의 .opensmith 디렉토리에 저장.
.gitignore에 추가하지 않습니다 (팀 공유 가능).

## 초기화

bugs.json이 없으면 자동 생성:
```json
{
  "project": "[프로젝트명]",
  "bugs": []
}
```

# Step 0: 시스템 PRD 읽기

## 실행

### 0-0. 미해결 버그 확인 (최우선)

```
.opensmith/bugs.json 이 존재하는가?
  ├─ 있다 → open 상태 버그 확인
  │   ├─ open 버그 있음
  │   │   "이전 QA에서 미해결 버그 N개가 있습니다. 이 버그를 먼저 해결합니다."
  │   │   → 버그 목록 사용자에게 표시
  │   │   → step5(구현)에서 해당 버그만 집중 수정하도록 feature_args에 버그 내용 포함
  │   └─ open 버그 없음 → 정상 진행
  └─ 없다 → 정상 진행
```

### 0-0b. GitHub 이슈 → Bug/Todo 동기화

**GitHub 이슈를 확인하고, 작업 중인 이슈를 Bug 또는 Todo로 자동 등록합니다.**

```bash
# GitHub 이슈 목록 가져오기 (open 상태, label: bug 또는 enhancement)
gh issue list --state open --json number,title,labels,assignees,body --limit 50
```

```
이슈 목록을 순회:
  각 이슈에 대해:
  ├─ label에 "bug"가 포함 → .opensmith/bugs.json에 등록 (중복 체크: github_issue 필드)
  │   {
  │     "id": "GH-[이슈번호]",
  │     "description": "[이슈 제목]",
  │     "severity": "medium" (기본값, critical/high label이 있으면 조정),
  │     "status": "open",
  │     "found_at": "[이슈 생성일]",
  │     "found_by": "github",
  │     "github_issue": [이슈번호],
  │     "feature": null,
  │     "file": null,
  │     "resolved_at": null
  │   }
  │
  └─ label에 "bug"가 아닌 이슈 (todo/enhancement/feature) → TaskCreate로 등록
      TaskCreate(
        subject="GH-[이슈번호]: [이슈 제목]",
        description="GitHub 이슈 #[번호]에서 동기화됨.\n\n[이슈 body 요약]"
      )

gh 명령 실패 시 (gh 미설치, 인증 없음 등) → 경고만 출력하고 정상 진행
```

### 0-1. 시스템 PRD 읽기

1. `docs/prd/system-prd.md` 읽기

```
없다 → 중단. "시스템 PRD가 없습니다. /prd 로 먼저 작성해주세요."
있다 → 아래 진행
```

2. 추출할 것:
   - 프로젝트 개요 (한 줄 요약, 타겟 사용자, 핵심 가치)
   - 기술 제약 (Section 6)
   - 기능 목록 (Section 9) — 전체 목록과 각 기능의 상태(Implemented/미작성)

3. `--all` 모드 처리:

```
--all 옵션인가?
  ├─ 맞다 → Section 9에서 상태가 "Implemented"가 아닌 기능을 전부 추출
  │   → 미구현 기능 목록을 메모 (순서대로 처리)
  │   → 첫 번째 기능부터 시작
  │
  └─ 아니다 (single) → $ARGUMENTS와 매칭되는 기능 찾기
```

4. **PRD 기능별 TODO 자동 생성:**

```
Section 9(기능 인덱스)의 모든 기능에 대해 TaskCreate를 호출합니다.

기능 목록을 순회:
  각 기능에 대해:
  ├─ 상태가 "Implemented" → 건너뜀
  └─ 미구현 → TaskCreate 호출
      TaskCreate(
        subject="[F-N] [기능명]",
        description="PRD 기능 구현\n- PRD: docs/prd/system-prd.md Section 9\n- 상태: 미구현\n- 우선순위: [P0/P1/P2]"
      )

--all 모드: 모든 미구현 기능에 대해 TODO 생성
single 모드: 현재 기능 1개만 TODO 생성
```

5. 다음 스텝 실행: `execute/steps/step1-feature-prd.md` 를 **반드시** Read하고 따르세요.

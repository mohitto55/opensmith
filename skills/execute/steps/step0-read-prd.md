# Step 0: 시스템 PRD 읽기

## 실행

### 0-0. 미해결 이슈 확인 (최우선)

```
.execute/issues.json 이 존재하는가?
  ├─ 있다 → open 상태 이슈 확인
  │   ├─ open 이슈 있음 → state.json의 pending_issues 확인
  │   │   "이전 QA에서 미해결 이슈 N개가 있습니다. 이 이슈를 먼저 해결합니다."
  │   │   → 이슈 목록 사용자에게 표시
  │   │   → step5(구현)에서 해당 이슈만 집중 수정하도록 feature_args에 이슈 내용 포함
  │   └─ open 이슈 없음 → 정상 진행
  └─ 없다 → 정상 진행
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
state.json의 mode가 "all"인가?
  ├─ 맞다 → Section 9에서 상태가 "Implemented"가 아닌 기능을 전부 추출
  │   → feature_queue에 저장 (ID 순서대로)
  │   → 첫 번째 기능을 feature_name, feature_args로 설정
  │
  └─ 아니다 (single) → $ARGUMENTS와 매칭되는 기능 찾기
      → feature_name, feature_args 설정
```

4. `.execute/state.json` 업데이트:

```json
{
  "system_prd_path": "docs/prd/system-prd.md",
  "project_context": { "summary": "...", "tech_stack": "...", "target_users": "..." },
  "matched_feature": "매칭된 기능명",
  "feature_name": "[현재 기능 kebab-case]",
  "feature_args": "[현재 기능 설명]",
  "feature_queue": ["F-2 기능명", "F-3 기능명", ...],
  "current_step": 1
}
```

`--all` 모드에서 `feature_queue`가 비어있으면 (전부 구현됨):
```
"모든 기능이 이미 구현되었습니다."
→ current_step = "done"
```

5. 다음 스텝 실행: `execute/steps/step1-feature-prd.md` 를 **반드시** Read하고 따르세요.

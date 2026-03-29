# Step 0: 시스템 PRD 읽기

## 실행

1. `docs/prd/system-prd.md` 읽기

```
없다 → 중단. "시스템 PRD가 없습니다. /prd 로 먼저 작성해주세요."
있다 → 아래 진행
```

2. 추출할 것:
   - 프로젝트 개요 (한 줄 요약, 타겟 사용자, 핵심 가치)
   - 기술 제약 (Section 6)
   - 기능 목록 (Section 9) — `$ARGUMENTS`와 매칭되는 기능 찾기

3. `.execute/state.json` 업데이트:

```json
{
  "system_prd_path": "docs/prd/system-prd.md",
  "project_context": { "summary": "...", "tech_stack": "...", "target_users": "..." },
  "matched_feature": "매칭된 기능명 또는 null",
  "current_step": 1
}
```

4. 다음 스텝 실행: `execute/steps/step1-feature-prd.md` 를 Read하고 따르세요.

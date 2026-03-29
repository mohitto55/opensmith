# Step 5: 구현

## 실행

`.execute/state.json`에서 읽기:
- `feature_prd_path`, `design_path`
- `memory_bank_context` (에러 패턴, 제약사항)
- `codebase_context` (관련 파일 목록)

agent-teams 호출:

```
Skill(skill="agent-teams", args="$FEATURE_ARGS

PRD: [feature_prd_path]
설계: [design_path]
위 문서에 따라 구현하세요. 설계에 없는 것은 구현하지 마세요.

관련 기존 코드:
[codebase_context.related_files]

Memory Bank 주의사항:
[memory_bank_context.errors]
[memory_bank_context.constraints]

참고 패턴:
[memory_bank_context.patterns]")
```

완료 후 state.json: `current_step = 6`

다음 스텝: `execute/steps/step6-build.md`

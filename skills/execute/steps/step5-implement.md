# Step 5: 구현

> **⛔ 금지**: 이 단계에서 `Agent(subagent_type=...)` 등 subagent를 직접 스폰하지 마세요.
> **반드시 `/agent-teams` (Skill)을 통해 팀 기반으로 구현해야 합니다.**
> subagent 직접 호출은 역할 분담, 태스크 추적, QA 검증이 누락되므로 금지합니다.

## 실행

다음 파일들을 읽어 컨텍스트를 확보합니다:
- Feature PRD: `docs/prd/features/[기능명]/README.md`
- 설계 문서: `docs/design/[기능명].md`
- 수집 컨텍스트: `docs/prd/features/[기능명]/context.md`

**TDD 필수**: agent-teams의 프론트엔드/백엔드 개발자는 반드시 테스트를 먼저 작성한 후 구현합니다 (Red → Green → Refactor).

## Agent Teams 활성화 (필수)

**반드시 `Skill` 도구를 사용하여 `opensmith:agent-teams` 스킬을 호출하세요.**
직접 Agent를 스폰하거나, 직접 코드를 작성하지 마세요.
agent-teams 스킬이 7역할 팀을 자동으로 구성하고 Phase 0~5를 실행합니다.

```
Skill(skill="opensmith:agent-teams", args="$FEATURE_ARGS

PRD: docs/prd/features/[기능명]/README.md
설계: docs/design/[기능명].md
위 문서에 따라 구현하세요. 설계에 없는 것은 구현하지 마세요.
TDD 필수: 모든 기능은 테스트 먼저 작성 후 구현 (Red → Green → Refactor).

수집 컨텍스트: docs/prd/features/[기능명]/context.md")
```

**주의:**
- `Skill(skill="opensmith:agent-teams", ...)` 형태로 호출해야 합니다. `skill="agent-teams"`만 쓰면 안 됩니다.
- agent-teams 스킬이 내부적으로 TeamCreate + Agent 스폰을 수행합니다. 중복 스폰하지 마세요.
- agent-teams 스킬이 완료될 때까지 대기한 후 다음 스텝으로 진행하세요.

완료 후 다음 스텝: **반드시** `execute/steps/step6-build.md`를 Read하고 따르세요.

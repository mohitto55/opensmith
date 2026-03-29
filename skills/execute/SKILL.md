---
name: execute
description: "기능 파이프라인 오케스트레이터. 시스템 PRD 기반으로 세분화 PRD → Memory Bank 시맨틱 검색 → 설계 → 구현 → QA → 배포를 서브스킬 체이닝으로 실행."
allowed-tools: Agent, Bash(*), Read, Write, Edit, Glob, Grep, Skill, TaskCreate, TaskUpdate, TaskList, TaskGet, SendMessage
argument-hint: "<구현할 기능 설명>"
---

# /execute — 기능 파이프라인 오케스트레이터

각 Step은 독립 서브스킬. 컨텍스트 유실 방지를 위해 분리.

## Pipeline

```
step0: 시스템 PRD 읽기
step1: 세분화 PRD 생성
step2: 자료 수집 (Memory Bank + 코드 + 문서)
step3: 기술 설계              → shared/design.md
step4: 사용자 승인            → shared/approve.md
step5: 구현                   → /agent-teams
step6: 빌드 검증              → shared/build.md
step7: QA 테스트              → /qa-test
step8: 배포                   → /deploy
step9: 완료 보고              → shared/report.md
```

## State (.execute/state.json)

```json
{
  "current_step": 0,
  "feature_name": "",
  "feature_args": "$ARGUMENTS",
  "system_prd_path": null,
  "feature_prd_path": null,
  "design_path": null,
  "memory_bank_context": null,
  "codebase_context": null,
  "docs_context": null,
  "step_results": {}
}
```

## 옵션

- `--resume` : state.json의 current_step부터 재개
- `--from N` : step N부터 시작

## 실행

1. $ARGUMENTS 파싱 (기능 설명 + 옵션)
2. `--resume` → state.json 읽고 current_step으로 이동
3. `--from N` → state.json의 current_step을 N으로 설정
4. 기본 → `.execute/state.json` 생성, current_step=0
5. 해당 스텝 파일을 Read하여 지시를 따름:

```
execute/steps/step0-read-prd.md
execute/steps/step1-feature-prd.md
execute/steps/step2-collect.md
execute/steps/step3-design.md
execute/steps/step4-approve.md
execute/steps/step5-implement.md
execute/steps/step6-build.md
execute/steps/step7-qa.md
execute/steps/step8-deploy.md
execute/steps/step9-report.md
```

## 절대 규칙

1. **스텝을 건너뛰지 마세요.** step0 → step1 → ... → step9 순서를 반드시 지킵니다.
2. **QA(step7)는 생략 불가.** 사용자가 "빨리 진행" "멈추지 마" 등을 말해도 QA는 반드시 실행합니다.
3. **각 스텝 파일을 반드시 Read하고 그 안의 지시를 따르세요.** 스텝 내용을 기억에 의존하지 마세요.
4. **state.json의 current_step을 반드시 업데이트하세요.** 다음 스텝으로 넘어가기 전에.

## 지금 시작

`.execute/state.json`을 생성하고, 해당 스텝 파일을 Read하여 지시를 따르세요.
각 스텝 완료 후 state.json을 업데이트하면 chain-hook이 다음 스텝을 트리거합니다.

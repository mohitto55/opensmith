---
name: execute
description: "기능 파이프라인 오케스트레이터. 시스템 PRD 기반으로 세분화 PRD → Memory Bank 시맨틱 검색 → 설계 → 구현 → QA → 배포를 서브스킬 체이닝으로 실행."
allowed-tools: Agent, Bash(*), Read, Write, Edit, Glob, Grep, Skill, TaskCreate, TaskUpdate, TaskList, TaskGet, SendMessage
argument-hint: "<구현할 기능 설명> [--all] [--from N]"
---

# /execute — 기능 파이프라인 오케스트레이터 (Stateless)

각 Step은 독립 서브스킬. **state.json 없이** 동작합니다.
컨텍스트는 Task 시스템 + 프로젝트 내 파일(docs/, .opensmith/)로 관리합니다.

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

## 상태 관리 — Stateless 설계

**state.json을 사용하지 않습니다.** 여러 터미널에서 동시 실행 가능.

상태 추적 방법:
1. **진행 상태**: TaskCreate/TaskUpdate로 추적 (세션 내)
2. **기능 PRD**: `docs/prd/features/[기능명]/README.md` (디스크에 영구 저장)
3. **설계 문서**: `docs/design/[기능명].md` (디스크에 영구 저장)
4. **수집 컨텍스트**: step2에서 수집한 내용을 `docs/prd/features/[기능명]/context.md`에 저장
5. **버그**: `.opensmith/bugs.json` (디스크에 영구 저장)
6. **PRD 구현 상태**: `docs/prd/system-prd.md` Section 9의 Implemented 마킹

**세션이 끊겨도 복구 가능**: 디스크의 PRD/설계/context 파일이 있으면 해당 스텝부터 재개.

## 옵션

- `--all` : system-prd.md의 미구현 기능을 **전부** 순서대로 실행
- `--from N` : step N부터 시작 (이전 스텝의 산출물이 디스크에 있어야 함)

## 실행

1. $ARGUMENTS 파싱 (기능 설명 + 옵션)
2. `--from N` → 해당 스텝의 전제조건(PRD/설계 파일 존재) 확인 후 시작
3. `--all` → system-prd.md 읽고 미구현 기능 목록 추출, 순서대로 실행
4. 기본 → step0부터 시작
5. **각 스텝 시작 전** TaskUpdate로 현재 진행 상태 기록
6. 해당 스텝 파일을 Read하여 지시를 따름:

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
4. **각 스텝 완료 시 TaskUpdate로 완료 표시하세요.** state.json은 사용하지 않습니다.
5. **사용자에게 불필요하게 묻지 마세요.** 아래 2가지 경우에만 사용자에게 질문합니다:
   - **step4 (사용자 승인)**: 설계 승인은 반드시 물어야 합니다.
   - **step8 (배포 승인)**: 배포 여부는 반드시 물어야 합니다.
   - 그 외 모든 스텝에서는 **멈추지 말고 자율적으로 판단하여 계속 진행하세요.**
   - "어떻게 할까요?", "진행할까요?", "다음으로 넘어갈까요?" 등의 질문 금지.
   - 이슈 발견 시에도 묻지 말고 즉시 수정을 시도하세요. 수정 불가 시에만 보고.

## 지금 시작

파이프라인 태스크를 TaskCreate로 생성하고, step0 파일을 Read하여 지시를 따르세요.

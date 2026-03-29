# 자가개선 순환 구조 (Self-Improvement Loop)

## 개요

LoopyEra의 핵심은 **무한 루프**: 코드 작성 → 검증 → 수정 → 배포 → 학습 → 강화 → (다시 코드 작성).
한 번 발생한 실수는 시스템이 학습하여 영원히 재발하지 않습니다.

---

## 순환 구조

```
                    ┌───────────────┐
                    │   코드 작성    │
                    │ {{AI_MODEL}}가 요청 + │
                    │ scaffold 규칙  │
                    │ 기반으로 작성   │
                    └───────┬───────┘
                            │
               ┌────────────┘
               ▼
    ┌───────────────┐              ┌───────────────┐
    │    강화        │              │    검증        │
    │ 새 NEVER DO   │              │ 30개 hook이    │
    │ 규칙이 같은    │              │ 타입, 린트,    │
    │ 실수를 영원히  │              │ scaffold 위반  │
    │ 방지           │              │ 자동 체크      │
    └───────┬───────┘              └───────┬───────┘
            │                              │
            │        ∞ 무한 루프            │
            │                              │
    ┌───────┴───────┐              ┌───────┴───────┐
    │    학습        │              │   자동 수정    │
    │ Fix 커밋 감지  │              │ Opus agent    │
    │ 팩트 추출      │              │ hook이 독립적  │
    │ scaffold       │              │ 으로 에러 수정  │
    │ 업데이트       │              │               │
    └───────┬───────┘              └───────┬───────┘
            │                              │
            └────────────┐   ┌─────────────┘
                         ▼   ▼
                    ┌───────────────┐
                    │    배포        │
                    │ 커밋 + 푸시    │
                    │ + 텔레그램     │
                    │ 알림           │
                    └───────────────┘
```

---

## 각 단계 상세

### 1단계: 코드 작성

**트리거**: 사용자 요청 또는 self-improve 태스크

**입력**:
- 사용자 요청 ("채팅 기능 수정해줘")
- Layer 2 scaffold 규칙 (frontend-patterns.md, backend-patterns.md)
- Layer 4 Memory Bank 관련 팩트

**동작**:
- {{AI_MODEL}}가 scaffold 규칙에 맞게 코드 작성
- NEVER DO 목록을 참조하여 금지된 패턴 회피
- 기존 코드 패턴과 일관성 유지

**출력**: 수정된 코드 파일

---

### 2단계: 검증

**트리거**: 코드 작성 완료 (PostToolUse: Write/Edit)

**실행되는 훅**:

| 훅 | 체크 항목 | 실패 시 |
|----|-----------|---------|
| H1 typecheck-gate | TypeScript / C# 타입 에러 | 차단 → 3단계로 |
| H2 lint-gate | ESLint / StyleCop 위반 | 차단 → 3단계로 |
| H3 scaffold-never-do | NEVER DO 규칙 위반 | 차단 → 3단계로 |
| H4 security-gate | 보안 위반 | 차단 → 3단계로 |
| H5 import-guard | 금지 라이브러리 사용 | 차단 → 3단계로 |
| H6 file-size-guard | 파일 크기 초과 | 경고/차단 |

**결과**: PASS → 4단계 배포 / FAIL → 3단계 자동 수정

---

### 3단계: 자동 수정

**트리거**: 2단계 검증 실패

**동작**:
1. 실패한 훅의 에러 메시지 수집
2. 에스컬레이션 레벨에 따라 처리:

```
실패 횟수 1~2: 1단계 에스컬레이션
  → additionalContext로 에러 주입
  → {{AI_MODEL}} 메인 스레드가 직접 수정

실패 횟수 3~5: 2단계 에스컬레이션
  → 독립 Opus 에이전트 스폰
  → 에이전트가 파일 읽기 + 에러 분석 + 수정
  → 메인 스레드와 병렬 실행

실패 횟수 6+: 3단계 에스컬레이션
  → 도구 실행 차단
  → 텔레그램 알림
  → "접근 방식 변경" 메시지
  → 카운터 리셋
  → 사람 개입 대기
```

**출력**: 수정된 코드 → 다시 2단계로

---

### 4단계: 배포

**트리거**: 2단계 검증 통과

**동작**:
1. Git 커밋 (변경 사항 자동 요약 메시지)
2. Git 푸시 (리모트 브랜치)
3. {{ORCHESTRATOR}} 배포 (dev-cycle 스킬)
4. 헬스체크 확인
5. 텔레그램 배포 알림

**배포 실패 시**: deploy-fix-agent (A5) 실행 → 매니페스트 수정 → 재배포

---

### 5단계: 학습

**트리거**: 커밋 성공 (PostCommit)

**동작**:

#### 5-1. Fix 커밋 감지
```bash
# 최근 커밋이 "fix" 키워드를 포함하는지 확인
LAST_MSG=$(git log -1 --format="%s")
if echo "$LAST_MSG" | grep -qi "fix\|버그\|수정\|에러\|hotfix"; then
  # Fix 커밋으로 판단 → 팩트 추출 트리거
  trigger_fact_extraction
fi
```

#### 5-2. 팩트 추출
- Haiku LLM으로 "무엇이 문제였고, 어떻게 해결했는지" 추출
- 추출된 팩트를 Facts DB에 저장
- 기존 팩트와 Consolidation (DUPLICATE/CONTRADICTION/EVOLUTION/INDEPENDENT)

#### 5-3. Scaffold 업데이트 검토
- 추출된 팩트가 새로운 코딩 패턴인 경우 → scaffold 업데이트 후보로 등록
- self-improve 태스크로 생성 (pending 상태)

---

### 6단계: 강화

**트리거**: self-improve 태스크 승인 또는 자동 적용

**동작**:

#### 6-1. NEVER DO 규칙 추가
에러 패턴에서 파생된 새로운 NEVER DO 규칙을 scaffold에 추가:

```markdown
# 예시: frontend-patterns.md에 추가

## NEVER DO
- `<input type="color">` 사용 금지 → `react-colorful` 사용
- 컴포넌트에서 직접 API 호출 금지 → lib/api.ts 통해서만
- [NEW] `useEffect` 내에서 state 업데이트 후 바로 참조 금지 → useRef 또는 callback 사용
```

#### 6-2. 패턴 파일 업데이트
새로 발견된 좋은 패턴을 scaffold 파일에 추가:

```markdown
# 예시: backend-patterns.md에 추가

## 패턴
- {{DATABASE}} 쿼리 시 항상 projection 사용 (필요한 필드만)
- [NEW] 에러 응답은 항상 { error: string, code: number } 형태로 통일
```

#### 6-3. 다음 세션 반영
- Layer 2 (Skills/Scaffold)에 자동 반영
- 다음 코드 작성 시 {{AI_MODEL}}가 강화된 규칙을 참조
- 같은 실수가 영원히 재발하지 않음

---

## /self-improve 스킬

자가개선을 수동으로 트리거하는 스킬:

```
사용자: /self-improve

{{AI_MODEL}}:
1. pending 상태의 self-improve 팩트 조회
2. 각 팩트의 적용 가능성 분석
3. scaffold 파일 업데이트 제안
4. 사용자 승인 시 적용
```

---

## 메트릭 추적

| 메트릭 | 수집 시점 | 저장 위치 |
|--------|-----------|-----------|
| 빌드 성공/실패 횟수 | BuildSuccess/BuildFail | metrics.db |
| 에스컬레이션 레벨 도달 | 에스컬레이션 발생 시 | metrics.db |
| NEVER DO 규칙 위반 횟수 | scaffold-never-do 훅 | metrics.db |
| 자동 수정 성공/실패 | Agent 훅 완료 시 | metrics.db |
| 새 팩트 추출 수 | fact-extraction 훅 | Facts DB |

---

## 관련 문서
- [PRD](./prd.md) - 전체 요구사항
- [Hook System](./hook-system.md) - 훅 시스템
- [Memory Bank](./memory-bank.md) - 메모리 뱅크
- [Escalation System](./escalation-system.md) - 에스컬레이션

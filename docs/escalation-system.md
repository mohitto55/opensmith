# 3단계 에스컬레이션 시스템

## 개요

코드에 에러가 있으면 시스템이 자동으로 단계를 올립니다.
3단계까지 사람 개입 불필요.

---

## 에스컬레이션 흐름

```
[에러 발생]
    │
    ▼
┌─────────────────────────────────────────┐
│  1단계: 소프트 알림                      │
│                                         │
│  additionalContext로 에러 메시지를        │
│  {{AI_MODEL}} 컨텍스트에 주입.                  │
│  {{AI_MODEL}}가 보고 수정.                     │
│                                         │
│  ✅ 자동 복구 가능                       │
└────────────────┬────────────────────────┘
                 │ 실패 (동일 에러 3회 반복)
                 ▼
┌─────────────────────────────────────────┐
│  2단계: 에이전트 수정                    │
│                                         │
│  Hook이 독립 Opus 에이전트를 생성.        │
│  파일 읽고, 에러 분석, 수정 적용.         │
│  메인 스레드와 병렬.                     │
│                                         │
│  🤖 Opus 기반                           │
└────────────────┬────────────────────────┘
                 │ 실패 (에이전트도 해결 못함)
                 ▼
┌─────────────────────────────────────────┐
│  3단계: 강제 차단                        │
│                                         │
│  도구 실행 차단.                         │
│  텔레그램 알림.                          │
│  "접근 방식 변경" 메시지.                 │
│  카운터 리셋.                            │
│                                         │
│  🚨 사람 개입 필요                       │
└─────────────────────────────────────────┘
```

---

## 각 단계 상세

### 1단계: 소프트 알림

**트리거**: HARD 게이트 훅 실패 (첫 1~2회)

**동작**:
1. 에러 메시지를 `additionalContext`에 주입
2. {{AI_MODEL}} 메인 스레드가 에러를 인식
3. {{AI_MODEL}}가 직접 코드 수정 시도
4. 수정 후 다시 HARD 게이트 통과 시도

**예시**:
```
[additionalContext 주입]
⚠️ typecheck-gate 실패:
  frontend/app/chat/[characterId]/page.tsx:42
  Type 'string' is not assignable to type 'number'.

해결 힌트: Memory Bank에서 유사 에러 검색 결과:
  - "characterId는 string으로 전달되므로 parseInt() 필요" (2026-03-15 세션)
```

**복구 성공 조건**: 같은 훅이 다음 시도에서 PASS

### 2단계: 에이전트 수정

**트리거**: 동일 HARD 게이트가 3회 연속 실패

**동작**:
1. Agent 훅이 독립 Opus 에이전트를 스폰
2. 에이전트에게 전달되는 컨텍스트:
   - 실패한 훅 이름 + 에러 메시지
   - 관련 파일 경로
   - Memory Bank에서 유사 에러 해결 히스토리
   - 현재 scaffold 규칙
3. 에이전트가 파일을 읽고 에러 분석
4. 에이전트가 수정 적용
5. 메인 스레드와 **병렬** 실행 (메인 작업 차단 안 함)

**에이전트 프롬프트 템플릿**:
```
당신은 {{PROJECT_NAME}} 프로젝트의 에러 수정 전문가입니다.

[에러 정보]
훅: {hook_name}
에러: {error_message}
파일: {file_path}
실패 횟수: {fail_count}

[관련 컨텍스트]
유사 에러 해결 히스토리:
{memory_bank_results}

scaffold 규칙:
{scaffold_rules}

[작업]
1. 관련 파일을 읽으세요
2. 에러의 근본 원인을 분석하세요
3. scaffold 규칙에 맞게 수정하세요
4. 수정 후 빌드가 성공하는지 확인하세요
```

**복구 성공 조건**: 에이전트의 수정 후 HARD 게이트 PASS

### 3단계: 강제 차단

**트리거**: 2단계 에이전트도 해결 실패 (총 실패 6회+)

**동작**:
1. **도구 실행 차단**: 해당 파일에 대한 Write/Edit 도구 차단
2. **텔레그램 알림**: 사용자에게 상세 에러 보고서 전송
3. **접근 방식 변경 메시지**: {{AI_MODEL}}에게 "현재 접근 방식을 포기하고 다른 방법을 시도하라" 지시
4. **카운터 리셋**: 에스컬레이션 카운터 초기화
5. **사람 대기**: 사용자의 지시 대기

**텔레그램 알림 형식**:
```
🚨 {{PROJECT_NAME}} 에스컬레이션 3단계

📄 파일: frontend/app/chat/[characterId]/page.tsx
🔧 훅: typecheck-gate
❌ 실패 횟수: 6
⏰ 시간: 2026-03-27 14:30 KST

에러:
Type 'string' is not assignable to type 'number'.
Line 42, Column 15

시도한 수정:
1. parseInt() 추가 → 런타임 NaN 발생
2. Number() 캐스팅 → 타입 불일치 유지
3. 에이전트: 인터페이스 타입 수정 → 다른 파일 타입 에러 연쇄

사람의 지시가 필요합니다.
```

---

## 에스컬레이션 카운터 관리

### 카운터 구조

```bash
# .claude/hooks/lib/escalation.sh

ESCALATION_DB=".claude/escalation.db"

# 카운터 증가
escalate_increment() {
  local hook_name=$1
  local file_path=$2
  local error_msg=$3

  sqlite3 $ESCALATION_DB "
    INSERT INTO escalation_counter (hook, file, error, count, updated_at)
    VALUES ('$hook_name', '$file_path', '$error_msg', 1, datetime('now'))
    ON CONFLICT(hook, file) DO UPDATE SET
      count = count + 1,
      error = '$error_msg',
      updated_at = datetime('now');
  "
}

# 현재 레벨 확인
escalate_level() {
  local hook_name=$1
  local file_path=$2

  local count=$(sqlite3 $ESCALATION_DB "
    SELECT count FROM escalation_counter
    WHERE hook='$hook_name' AND file='$file_path';
  ")

  if [ "$count" -le 2 ]; then echo "1"      # 소프트 알림
  elif [ "$count" -le 5 ]; then echo "2"     # 에이전트 수정
  else echo "3"                               # 강제 차단
  fi
}

# 카운터 리셋
escalate_reset() {
  local hook_name=$1
  local file_path=$2

  sqlite3 $ESCALATION_DB "
    DELETE FROM escalation_counter
    WHERE hook='$hook_name' AND file='$file_path';
  "
}
```

### 카운터 DB 스키마

```sql
CREATE TABLE escalation_counter (
  hook TEXT NOT NULL,
  file TEXT NOT NULL,
  error TEXT,
  count INTEGER DEFAULT 0,
  updated_at TEXT,
  PRIMARY KEY (hook, file)
);

CREATE TABLE escalation_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  hook TEXT NOT NULL,
  file TEXT NOT NULL,
  level INTEGER NOT NULL,
  error TEXT,
  resolution TEXT,  -- auto_fixed / agent_fixed / human_fixed / abandoned
  created_at TEXT NOT NULL
);
```

---

## 에스컬레이션 히스토리 분석

에스컬레이션 히스토리를 분석하여 자가개선 루프에 피드백:

```bash
# 자주 3단계까지 올라가는 패턴 감지
sqlite3 $ESCALATION_DB "
  SELECT hook, file, COUNT(*) as freq
  FROM escalation_history
  WHERE level = 3
  GROUP BY hook, file
  ORDER BY freq DESC
  LIMIT 5;
"
# → 결과를 self-improve 태스크로 등록
# → scaffold 강화 또는 훅 로직 개선
```

---

## 관련 문서
- [PRD](./prd.md) - 전체 요구사항
- [Hook System](./hook-system.md) - 훅 시스템
- [Self-Improvement Loop](./self-improvement-loop.md) - 자가개선 루프
- [5-Layer Architecture](./architecture-5layer.md) - 레이어 아키텍처

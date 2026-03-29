---
name: self-improve
description: "자가개선 루프 실행. pending self-improve 팩트를 검토하고, scaffold 파일을 업데이트하며, NEVER DO 규칙을 추가. '/self-improve', '자가개선', 'scaffold 업데이트' 등을 요청할 때 사용."
allowed-tools: Bash(*), Read, Write, Edit, Glob, Grep
---

# Self-Improve — 자가개선 루프 스킬

이 스킬은 LoopyEra 자가개선 순환 구조의 핵심입니다.
pending 상태의 self-improve 팩트를 검토하고, scaffold 파일을 자동 업데이트합니다.

## 실행 절차

### Step 1: pending self-improve 팩트 조회

```bash
sqlite3 .claude/memory-bank/memory.db "
  SELECT id, fact, confidence, created_at FROM facts
  WHERE type = 'self-improve' AND status = 'pending'
  ORDER BY confidence DESC;
"
```

### Step 2: 각 팩트 분석

각 pending 팩트에 대해:
1. 팩트 내용을 읽고 적용 가능성 판단
2. 관련 scaffold 파일 확인 (frontend-patterns.md, backend-patterns.md, never-do.md)
3. 이미 존재하는 규칙과 중복/충돌 여부 확인

### Step 3: scaffold 업데이트

#### NEVER DO 규칙 추가 시
`.claude/skills/never-do.md`의 `<!-- AUTO-GENERATED RULES START -->` ~ `<!-- AUTO-GENERATED RULES END -->` 영역에 추가:

```markdown
| AUTONN | [규칙 설명] | [원인: 커밋 해시/날짜] | [대안] |
```

#### 패턴 추가 시
해당 패턴 파일 (frontend-patterns.md 또는 backend-patterns.md)의 적절한 섹션에 추가.

### Step 4: 팩트 상태 업데이트

적용한 팩트의 상태를 `active`로 변경:
```bash
sqlite3 .claude/memory-bank/memory.db "
  UPDATE facts SET status = 'active', updated_at = datetime('now')
  WHERE id = '<fact_id>';
"
```

거절한 팩트의 상태를 `superseded`로 변경:
```bash
sqlite3 .claude/memory-bank/memory.db "
  UPDATE facts SET status = 'superseded', updated_at = datetime('now')
  WHERE id = '<fact_id>';
"
```

### Step 5: 결과 보고

```
## Self-Improve 결과

적용: N개
- [팩트 내용] → [적용 위치]

거절: M개
- [팩트 내용] → [거절 이유]

보류: K개
- [팩트 내용] → [추가 검토 필요]
```

## 자동 트리거

이 스킬은 다음 상황에서 자동으로 트리거됩니다:
1. SessionStart 시 `self-improve-check.sh` 훅이 pending 팩트를 감지
2. Fix 커밋 후 `extract-facts.sh`가 새 self-improve 팩트 생성
3. 사용자가 `/self-improve` 명령으로 수동 실행

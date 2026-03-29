---
name: scaffold-update
description: "scaffold 패턴 파일 수동 업데이트. 새 패턴/규칙을 frontend-patterns.md, backend-patterns.md, never-do.md에 추가. 'scaffold 업데이트', '패턴 추가', 'NEVER DO 추가' 등을 요청할 때 사용."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(sqlite3 *)
---

# Scaffold Update — 패턴 파일 업데이트 스킬

## 실행 절차

### 1. 현재 scaffold 상태 확인

```bash
# NEVER DO 규칙 수 확인
grep -c "^|" .claude/skills/never-do.md

# 자동 생성 규칙 수 확인
sed -n '/AUTO-GENERATED RULES START/,/AUTO-GENERATED RULES END/p' .claude/skills/never-do.md | grep -c "^|"
```

### 2. 규칙/패턴 추가

사용자 요청 `$ARGUMENTS`에 따라:

#### NEVER DO 규칙 추가
`.claude/skills/never-do.md`의 해당 섹션(프론트엔드/백엔드/인프라)에 추가.

자동 생성 영역에 추가하는 경우:
```markdown
<!-- AUTO-GENERATED RULES START -->
| AUTONN | [규칙] | [날짜: YYYY-MM-DD] [원인] | [대안] |
<!-- AUTO-GENERATED RULES END -->
```

#### 패턴 추가
해당 패턴 파일의 적절한 섹션에 추가.

### 3. Memory Bank에 기록

```bash
bash .claude/memory-bank/add-fact.sh pattern "[추가된 패턴/규칙]" 0.9 '["scaffold"]'
```

### 4. 결과 보고

변경된 파일과 추가된 내용을 보고.

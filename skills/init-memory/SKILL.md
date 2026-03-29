---
name: init-memory
description: "Memory Bank 초기화. SQLite + sqlite-vec DB 생성, 임베딩 모델 설치, 기존 대화 인덱싱. 'memory 초기화', 'init memory' 등을 요청할 때 사용."
allowed-tools: Bash(*), Read, Write
argument-hint: "[--force]"
---

# /init-memory — Memory Bank 초기화

## 사전 요구사항

Python 3.8+ 필요. 아래 패키지를 자동 설치합니다.

## 실행 순서

### 1. Python 패키지 설치

```bash
pip install sentence-transformers sqlite-vec anthropic 2>/dev/null || pip install --user sentence-transformers sqlite-vec anthropic
```

- `sentence-transformers`: 임베딩 모델 (all-MiniLM-L6-v2)
- `sqlite-vec`: SQLite 벡터 검색 확장
- `anthropic`: 팩트 추출용 Haiku API (선택)

### 2. DB 초기화

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/init-db.py
```

생성되는 것:
- `.opensmith/memory-bank/memory.db` — SQLite DB
- `.opensmith/memory-bank/meta.json` — 메타데이터 (vec 활성 여부 등)

### 3. 기존 대화 인덱싱 (선택)

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/parse-conversations.py
```

`~/.claude/projects/` 의 기존 대화 로그를 파싱하여 exchange 쌍으로 변환 후 DB에 저장합니다.

### 4. 임베딩 생성

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/embed.py
```

저장된 exchange에 384-dim 벡터 임베딩을 생성합니다. 첫 실행 시 모델 다운로드(~80MB).

### 5. 검증

```bash
# DB 상태 확인
sqlite3 .opensmith/memory-bank/memory.db "SELECT COUNT(*) FROM exchanges; SELECT COUNT(*) FROM facts;"

# 검색 테스트
bash ${CLAUDE_PLUGIN_ROOT}/hooks/lib/memory-query.sh --top-project-facts 3
```

## 완료 안내

```
Memory Bank 초기화 완료!

DB: .opensmith/memory-bank/memory.db
Exchange: N개 인덱싱
벡터 검색: 활성/비활성
임베딩 모델: all-MiniLM-L6-v2 (384-dim)

팩트 추출은 세션 종료 시 자동으로 실행됩니다 (fact-extraction 훅).
수동 추출: python3 ${CLAUDE_PLUGIN_ROOT}/scripts/extract-facts.py
```

## .gitignore 추가

Memory Bank DB는 프로젝트별 로컬 데이터이므로 gitignore에 추가:

```bash
echo ".opensmith/memory-bank/" >> .gitignore
```

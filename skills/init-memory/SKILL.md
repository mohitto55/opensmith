---
name: init-memory
description: "Memory Bank 초기화. 현재 프로젝트의 SQLite + sqlite-vec DB 생성, 임베딩 모델 설치, 현재 프로젝트 대화만 인덱싱, 초기 팩트 배치 추출. 'memory 초기화', 'init memory' 등을 요청할 때 사용."
allowed-tools: Bash(*), Read, Write, Edit
argument-hint: "[--force] [--skip-extract]"
---

# /init-memory — Memory Bank 초기화

Memory Bank는 **현재 프로젝트의** 결정·패턴·제약·에러를 기억하는 로컬 시맨틱 검색 저장소.

## 핵심 원칙 (절대 규칙)

1. **프로젝트 격리**: Memory Bank는 현재 작업 디렉터리(cwd)에 속한 프로젝트의 대화만 저장한다. `~/.claude/projects/` 전체를 인덱싱하면 다른 프로젝트 지식이 섞여 검색 품질이 망가진다.
2. **DB 위치**: `.opensmith/memory-bank/memory.db` (프로젝트 루트 내부). 전역 DB 금지.
3. **팩트의 의미**: "재사용할 가치가 있는 이 프로젝트 특유의 지식"만 저장. 일반 프로그래밍 상식은 팩트가 아니다.

## 사전 요구사항

- Python 3.8+
- `claude` CLI (배치 팩트 추출에 `claude -p` 사용)

## 실행 순서

### 1. Python 패키지 설치

```bash
pip install sentence-transformers sqlite-vec 2>/dev/null || pip install --user sentence-transformers sqlite-vec
```

- `sentence-transformers`: 임베딩 모델 (all-MiniLM-L6-v2, 첫 실행 시 ~80MB 다운로드)
- `sqlite-vec`: SQLite 벡터 검색 확장

### 2. DB 초기화

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/init-db.py
```

생성되는 것:
- `.opensmith/memory-bank/memory.db` — SQLite DB (exchanges, facts, FTS5, vec 인덱스)
- `.opensmith/memory-bank/meta.json` — 메타데이터 (vec 활성 여부 등)

### 3. 현재 프로젝트 대화 인덱싱

**중요**: 반드시 현재 프로젝트만 인덱싱한다. 기본 동작이 현재 프로젝트 필터이므로 옵션 없이 실행.

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/parse-conversations.py
```

이 스크립트는 cwd를 Claude Code 프로젝트 slug(예: `C--Users-admin-git-Python-opensmith`)로 변환해 해당 폴더의 JSONL만 읽는다.

절대 `--all`을 쓰지 말 것. 다른 프로젝트 대화가 섞이면 검색 결과가 오염된다.

### 4. Exchange 임베딩 생성

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/embed.py
```

저장된 exchange에 384-dim 벡터 임베딩을 생성한다. facts는 5단계에서 함께 임베딩됨.

### 5. 초기 팩트 배치 추출 (권장)

과거 대화에서 팩트를 한 번에 뽑아 Memory Bank를 부팅한다. `claude -p` 서브프로세스를 사용하며 API 키 불필요(현재 로그인 크레덴셜 재사용).

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/batch-extract-facts.py
```

- 30 exchange씩 배치 단위 → Haiku로 팩트 JSON 추출 → `confidence >= 0.7` 만 저장
- 중복은 fact 텍스트 해시 ID + `INSERT OR IGNORE`로 자동 제거
- 완료 후 `embed.py` 한 번 더 돌려 새 facts 벡터화

`--skip-extract` 인자가 주어졌으면 이 단계를 건너뛴다.

### 6. 훅 설치 (SessionStart 컨텍스트 주입)

훅이 없으면 세션 시작 시 관련 팩트가 자동 주입되지 않는다.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/setup.sh
```

`setup.sh`가 프로젝트에 `.claude/settings.json`을 생성하여 SessionStart/PreToolUse/PostToolUse 훅을 등록한다. 이미 `.claude/settings.json`이 있으면 사용자에게 병합 여부를 확인한다.

### 7. 검증

```bash
# DB 상태
python -c "import sqlite3; c=sqlite3.connect('.opensmith/memory-bank/memory.db'); print('exchanges:', c.execute('SELECT COUNT(*) FROM exchanges').fetchone()[0]); print('facts:', c.execute('SELECT COUNT(*) FROM facts').fetchone()[0])"

# 프로젝트 격리 검증: session_id가 모두 현재 프로젝트인지
python -c "
import sqlite3
from pathlib import Path
cwd_slug = str(Path.cwd().resolve()).replace('\\\\', '/').replace('/', '-').replace(':', '-').strip('-')
proj_dir = Path.home() / '.claude' / 'projects' / cwd_slug
ok = {f.stem for f in proj_dir.glob('*.jsonl')} if proj_dir.exists() else set()
conn = sqlite3.connect('.opensmith/memory-bank/memory.db')
db = {r[0] for r in conn.execute('SELECT DISTINCT session_id FROM exchanges')}
foreign = db - ok
print('foreign sessions:', len(foreign), '(반드시 0이어야 정화됨)')
"
```

`foreign sessions: 0`이 아니면 DB가 오염된 것. `memory.db` 삭제 후 처음부터 재실행.

## 완료 안내

```
Memory Bank 초기화 완료

DB:       .opensmith/memory-bank/memory.db
Exchange: N개 (현재 프로젝트만)
Facts:    M개 (confidence >= 0.7)
벡터:     활성 (384-dim, all-MiniLM-L6-v2)
훅:       .claude/settings.json 등록됨

다음 세션부터 SessionStart 시 관련 팩트 자동 주입.
```

## .gitignore 추가

Memory Bank DB는 프로젝트별 로컬 데이터. 커밋하지 않는다.

```bash
echo ".opensmith/memory-bank/" >> .gitignore
```

## 트러블슈팅

- **"foreign sessions > 0"**: 과거에 `--all` 또는 필터 없는 구버전 `parse-conversations.py`로 인덱싱한 흔적. `memory.db` 삭제 후 이 스킬 재실행.
- **facts 0개**: `claude -p` 호출 실패. `claude` CLI 로그인 상태 확인(`claude /login`). `.opensmith/batch-extract.log` 확인.
- **"no such module: vec0"**: `sqlite_vec.load()`로 확장을 로드해야 한다. Python 스크립트는 자동 처리, sqlite3 CLI는 미지원.
- **임베딩 없음**: `embed.py`를 facts 추출 후 재실행 필요.

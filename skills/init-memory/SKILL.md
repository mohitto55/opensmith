---
name: init-memory
description: "Memory Bank 초기화. 현재 프로젝트의 SQLite + sqlite-vec DB 생성, 임베딩 모델 설치, 현재 프로젝트 대화만 인덱싱, 초기 팩트 배치 추출. 'memory 초기화', 'init memory' 등을 요청할 때 사용."
allowed-tools: Bash(*), Read, Write, Edit
argument-hint: "[--force]"
---

# /init-memory — Memory Bank 초기화

Memory Bank는 **현재 프로젝트의** 결정·패턴·제약·에러를 기억하는 로컬 시맨틱 검색 저장소.

## 핵심 원칙 (절대 규칙)

1. **프로젝트 격리**: 현재 작업 디렉터리(cwd)에 속한 프로젝트의 대화만 저장. `~/.claude/projects/` 전체 인덱싱 금지 — 다른 프로젝트 지식이 섞이면 검색 품질이 망가진다.
2. **DB 위치**: `.opensmith/memory-bank/memory.db` (프로젝트 루트 내부). 전역 DB 금지.
3. **팩트의 의미**: "재사용할 가치가 있는 이 프로젝트 특유의 지식"만 저장. 일반 프로그래밍 상식은 팩트가 아니다.

## 옵션

- 인자 없음: 기존 DB 있으면 재사용하고 증분 인덱싱
- `--force`: 기존 DB 삭제 후 처음부터 재생성

## 사전 요구사항

- Python 3.8+
- `claude` CLI (Step 4 배치 팩트 추출에 사용)

## 실행 순서

### 1. Python 패키지 설치

```bash
pip install sentence-transformers sqlite-vec 2>/dev/null || pip install --user sentence-transformers sqlite-vec
```

- `sentence-transformers`: 임베딩 모델 (all-MiniLM-L6-v2, 첫 실행 시 ~80MB 다운로드)
- `sqlite-vec`: SQLite 벡터 검색 확장

### 2. DB 초기화 (멱등)

```bash
# 재사용 모드 (기본): 기존 DB 있으면 유지
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/init-db.py

# 강제 재생성: --force 인자가 들어왔다면
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/init-db.py --force
```

생성물:
- `.opensmith/memory-bank/memory.db` — SQLite DB (exchanges, facts, FTS5, vec 인덱스)
- `.opensmith/memory-bank/meta.json` — `vec_enabled`, 임베딩 모델 등

### 3. 현재 프로젝트 대화 인덱싱

기본 동작이 현재 프로젝트 필터이므로 옵션 없이 실행. **`--all` 사용 금지**.

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/parse-conversations.py
```

스크립트는 cwd를 Claude Code 프로젝트 slug(예: `C--Users-admin-git-Python-opensmith`)로 변환해 해당 폴더의 JSONL만 읽는다. 같은 exchange는 해시 ID로 중복 제거되므로 재실행 안전.

### 4. 초기 팩트 배치 추출

과거 대화에서 팩트를 한 번에 뽑아 Memory Bank를 부팅한다. `claude -p --model haiku` 서브프로세스를 사용하며 **별도 API 키 불필요**(현재 로그인 크레덴셜 재사용).

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/batch-extract-facts.py
```

- 30 exchange씩 배치 → Haiku로 팩트 JSON 추출 → `confidence >= 0.7` 만 저장
- 중복은 fact 텍스트 SHA-256 해시 + `INSERT OR IGNORE`로 자동 제거
- 옵션: `--dry-run`(1배치만), `--batches N`(N개 배치만), `--offset K`(K번째부터)

Exchange가 많으면 수 분 소요. 완료 후 배치 로그는 `.opensmith/batch-extract.log`(있는 경우).

### 5. 임베딩 생성 (Exchange + Facts 한 번에)

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/embed.py
```

임베딩이 없는 exchange와 facts를 모두 처리한다. 재실행해도 이미 임베딩 있는 행은 스킵.

### 6. 훅 설치 (SessionStart 컨텍스트 주입)

**훅이 없으면 다음 세션에서 관련 팩트가 자동 주입되지 않는다.** init-memory는 DB만 만들 뿐, 세션 훅은 별도 설치 필요.

```bash
# 1회성 설정: config.yaml 작성 (예시 복사)
cp ${CLAUDE_PLUGIN_ROOT}/config.example.yaml ./config.yaml

# 설치 (yq 필요)
bash ${CLAUDE_PLUGIN_ROOT}/setup.sh --config ./config.yaml
```

`setup.sh`는 프로젝트에 `.claude/settings.json` + `.claude/hooks/` 를 생성한다. 기존 `settings.json`이 있으면 `.bak` 으로 백업.

**주의**: `setup.sh`는 `--project-name`, `--project-dir` 등 여러 필수 인자를 요구한다. config.yaml 방식이 단순하다. yq 미설치 환경에서는 `bash setup.sh --help` 로 인자 확인 후 명령줄 인자로 실행.

### 7. 검증

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/scripts/verify-memory.py
```

점검 항목:
- Exchange / Facts 개수
- 임베딩 누락 여부
- **Foreign sessions = 0** (타 프로젝트 세션이 섞여있지 않은지)

문제 발견 시 exit code 2 + 권장 조치 출력.

## 완료 안내

```
Memory Bank 초기화 완료

DB:       .opensmith/memory-bank/memory.db
Exchange: N개 (현재 프로젝트만)
Facts:    M개 (confidence >= 0.7)
벡터:     활성 (384-dim, all-MiniLM-L6-v2)
훅:       .claude/settings.json (setup.sh 실행 시)

다음 세션부터 SessionStart 훅이 관련 팩트를 자동 주입 (훅 설치 시).
```

## .gitignore

Memory Bank DB는 프로젝트별 로컬 데이터. 커밋 금지.

```bash
grep -qxF ".opensmith/memory-bank/" .gitignore 2>/dev/null || echo ".opensmith/memory-bank/" >> .gitignore
```

## 트러블슈팅

- **`foreign sessions > 0`**: 과거 구버전 `parse-conversations.py`로 인덱싱한 흔적. `python3 scripts/init-db.py --force` 로 재시작.
- **facts 0개**: `claude -p` 호출 실패. `claude /login` 으로 로그인 확인, 또는 `.opensmith/batch-extract.log` 확인.
- **"no such module: vec0"**: sqlite3 CLI는 `vec0` 확장을 로드하지 않는다. Python 스크립트는 `sqlite_vec.load(conn)`으로 자동 처리하므로 Python만 사용.
- **임베딩 없는 facts 남음**: `python3 scripts/embed.py` 재실행.
- **`claude -p` 이 비싸다**: 현재 로그인(OAuth)이라면 구독 플랜 한도만 소모, 현금 청구 없음. API 키 모드라면 Haiku 기준 100 exchange ≈ $0.2~0.5.

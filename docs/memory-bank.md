# Memory Bank 데이터 파이프라인

## 개요

Memory Bank는 두 개의 병렬 파이프라인으로 원시 대화를 검색 가능한 팩트로 변환합니다.
시맨틱 검색(cosine similarity) + 전문 검색(FTS)의 하이브리드 방식으로
과거 의사결정, 에러 패턴, 프로젝트 제약사항을 실시간으로 제공합니다.

---

## 파이프라인 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                  대화 인덱싱 파이프라인                        │
│                                                             │
│  대화         파서          Embeddings      SQLite+vec       │
│  ┌──────┐    ┌──────┐     ┌──────────┐    ┌────────────┐   │
│  │JSONL │───►│parser│────►│384-dim   │───►│exchanges   │   │
│  │files │    │.ts   │     │all-Mini  │    │table       │   │
│  │~/.cl/│    │user/ │     │LM-L6-v2 │    │vec_exchanges│  │
│  │proj/ │    │asst  │     │          │    │index       │   │
│  └──────┘    │pairs │     └──────────┘    └─────┬──────┘   │
│              └──────┘                           │          │
│                                                 ▼          │
│                                          Semantic Search    │
│                                          cosine similarity  │
│                                          FTS hybrid         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  팩트 추출 파이프라인                          │
│                                                             │
│  Session    Fact          통합           Facts DB            │
│  End        Extraction                                      │
│  ┌──────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐     │
│  │Stop  │─►│Haiku LLM │─►│dedup/    │─►│2,600+ facts│     │
│  │hook  │  │decisions/│  │contradict│  │vec_facts   │     │
│  │trig. │  │patterns  │  │/evolve/  │  │index       │     │
│  └──────┘  └──────────┘  │keep      │  └─────┬──────┘     │
│                          └──────────┘        │             │
│                                              ▼             │
│                                         Ontology           │
│                                         domains/categories │
│                                         INFLUENCES/SUPPORTS│
└─────────────────────────────────────────────────────────────┘
```

---

## 파이프라인 1: 대화 인덱싱

### 1-1. 대화 수집 (JSONL)

**소스**: `~/.claude/projects/` 디렉토리의 대화 로그 파일

```
~/.claude/projects/<project-hash>/
├── conversations/
│   ├── 2026-03-18-session1.jsonl
│   ├── 2026-03-19-session2.jsonl
│   └── ...
```

### 1-2. 파서 (parser.ts)

대화 로그에서 user/assistant 쌍을 추출합니다.

```typescript
interface Exchange {
  id: string;
  timestamp: string;
  user_message: string;
  assistant_message: string;
  tools_used: string[];
  files_modified: string[];
  session_id: string;
}
```

**파싱 규칙**:
- user 메시지와 바로 다음 assistant 메시지를 하나의 exchange로 묶음
- tool_use 블록에서 사용된 도구와 수정된 파일을 추출
- 시스템 메시지는 제외

### 1-3. 임베딩 (Embeddings)

| 항목 | 값 |
|------|-----|
| 모델 | all-MiniLM-L6-v2 |
| 차원 | 384 |
| 실행 방식 | 로컬 Python 또는 임베딩 서버 |

**임베딩 대상**: `user_message + assistant_message`를 연결하여 하나의 벡터로 변환

### 1-4. SQLite + vec 저장

```sql
-- exchanges 테이블
CREATE TABLE exchanges (
  id TEXT PRIMARY KEY,
  timestamp TEXT NOT NULL,
  user_message TEXT NOT NULL,
  assistant_message TEXT NOT NULL,
  tools_used TEXT,  -- JSON array
  files_modified TEXT,  -- JSON array
  session_id TEXT NOT NULL,
  embedding BLOB NOT NULL  -- 384-dim float32 vector
);

-- 벡터 인덱스
CREATE VIRTUAL TABLE vec_exchanges USING vec0(
  id TEXT PRIMARY KEY,
  embedding float[384]
);

-- 전문 검색 인덱스
CREATE VIRTUAL TABLE fts_exchanges USING fts5(
  user_message,
  assistant_message,
  content='exchanges',
  content_rowid='rowid'
);
```

### 1-5. 시맨틱 검색

**하이브리드 검색** (cosine similarity + FTS):

```sql
-- 1단계: 벡터 유사도 검색 (top-20)
SELECT e.*, vec_distance_cosine(v.embedding, :query_vec) as vec_score
FROM vec_exchanges v
JOIN exchanges e ON v.id = e.id
ORDER BY vec_score ASC
LIMIT 20;

-- 2단계: FTS 키워드 매칭 (top-20)
SELECT e.*, rank as fts_score
FROM fts_exchanges f
JOIN exchanges e ON f.rowid = e.rowid
WHERE fts_exchanges MATCH :query_text
ORDER BY rank
LIMIT 20;

-- 3단계: RRF (Reciprocal Rank Fusion) 결합
-- final_score = 1/(k + vec_rank) + 1/(k + fts_rank), k=60
-- top-K 결과 반환 (보통 K=5)
```

---

## 파이프라인 2: 팩트 추출

### 2-1. 세션 종료 트리거

Stop 훅(`fact-extraction.sh`)이 세션 종료 시 자동 실행.

### 2-2. Fact Extraction (Haiku LLM)

{{AI_MODEL}} Haiku 4.5를 사용하여 세션 대화에서 팩트를 추출합니다.

**추출 대상**:
- **decisions**: 기술 선택, 아키텍처 결정 ("{{DATABASE}}를 선택한 이유는...")
- **patterns**: 발견된 코드 패턴 ("이 프로젝트에서는 X 패턴을 사용")
- **errors**: 에러와 해결 방법 ("X 에러는 Y로 해결")
- **constraints**: 프로젝트 제약사항 ("Z 라이브러리는 사용하지 않음")

**프롬프트 (Haiku)**:
```
다음 대화에서 미래 세션에 유용한 팩트를 추출하세요.

카테고리:
- decision: 기술/아키텍처 선택과 그 이유
- pattern: 프로젝트의 코딩 패턴/컨벤션
- error: 에러와 해결 방법
- constraint: 프로젝트 제약사항
- self-improve: 개선이 필요한 패턴

각 팩트는 JSON 형식으로:
{"type": "decision", "fact": "...", "confidence": 0.8, "tags": ["backend", "mongodb"]}
```

### 2-3. 통합 (Consolidation)

새 팩트를 기존 팩트 DB와 비교하여 관계를 결정합니다.

| 관계 | 조건 | 처리 |
|------|------|------|
| **DUPLICATE** | cosine similarity > 0.95 | 기존 팩트에 merge, 카운터 증가 |
| **CONTRADICTION** | cosine similarity > 0.7 + 의미 반대 | 이전 버전 기록 후 새 팩트로 교체 |
| **EVOLUTION** | cosine similarity > 0.8 + 내용 확장 | 이전 버전 기록 + 팩트 업데이트 |
| **INDEPENDENT** | cosine similarity < 0.7 | 새 팩트로 추가 |

### 2-4. Facts DB

```sql
-- facts 테이블
CREATE TABLE facts (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,  -- decision/pattern/error/constraint/self-improve
  fact TEXT NOT NULL,
  confidence REAL DEFAULT 0.5,
  tags TEXT,  -- JSON array
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  source_session TEXT,
  version INTEGER DEFAULT 1,
  status TEXT DEFAULT 'active',  -- active/superseded/pending
  embedding BLOB NOT NULL
);

-- 팩트 히스토리 (EVOLUTION/CONTRADICTION 추적)
CREATE TABLE fact_history (
  id TEXT PRIMARY KEY,
  fact_id TEXT REFERENCES facts(id),
  previous_fact TEXT NOT NULL,
  relation TEXT NOT NULL,  -- CONTRADICTION/EVOLUTION
  changed_at TEXT NOT NULL
);

-- 벡터 인덱스
CREATE VIRTUAL TABLE vec_facts USING vec0(
  id TEXT PRIMARY KEY,
  embedding float[384]
);

-- 전문 검색
CREATE VIRTUAL TABLE fts_facts USING fts5(
  fact,
  tags,
  content='facts',
  content_rowid='rowid'
);
```

### 2-5. Ontology

팩트 간 관계를 그래프로 관리합니다.

```sql
-- 온톨로지 테이블
CREATE TABLE ontology (
  id TEXT PRIMARY KEY,
  source_fact_id TEXT REFERENCES facts(id),
  target_fact_id TEXT REFERENCES facts(id),
  relation TEXT NOT NULL,  -- INFLUENCES/SUPPORTS/CONTRADICTS/REQUIRES
  strength REAL DEFAULT 0.5
);

-- 도메인/카테고리 테이블
CREATE TABLE domains (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,  -- backend/frontend/infra/security/performance
  description TEXT
);

CREATE TABLE fact_domains (
  fact_id TEXT REFERENCES facts(id),
  domain_id TEXT REFERENCES domains(id),
  PRIMARY KEY (fact_id, domain_id)
);
```

---

## 검색 API

### 시맨틱 검색

```bash
# 쿼리 텍스트를 임베딩으로 변환 후 top-K 검색
memory-query.sh "채팅 기능 에러 패턴" --top-k 5 --type error
```

### 도메인별 검색

```bash
# 특정 도메인의 팩트만 검색
memory-query.sh "성능 최적화" --domain backend --top-k 3
```

### 컨텍스트 주입용 검색

```bash
# inject-context.sh에서 사용
# 세션 시작 시 프로젝트 전반에 걸친 중요 팩트 top-5
memory-query.sh --top-project-facts 5
```

---

## 데이터 볼륨 예상

| 항목 | 6개월 후 | 1년 후 |
|------|----------|--------|
| 대화 (exchanges) | ~10K | ~50K |
| 팩트 (facts) | ~500 | ~2,600 |
| 임베딩 벡터 크기 | ~15MB | ~75MB |
| SQLite DB 크기 | ~30MB | ~150MB |
| 검색 응답 시간 | < 100ms | < 500ms |

---

## 관련 문서
- [PRD](./prd.md) - 전체 요구사항
- [Context Stack](./context-stack.md) - 컨텍스트 스택
- [Self-Improvement Loop](./self-improvement-loop.md) - 자가개선 루프
- [Hook System](./hook-system.md) - 훅 시스템

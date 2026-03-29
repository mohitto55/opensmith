#!/usr/bin/env python3
"""OpenSmith Memory Bank DB 초기화 스크립트.

SQLite + sqlite-vec 기반 Memory Bank를 생성하고 스키마를 초기화합니다.
"""

import sqlite3
import os
import sys
import json

def get_db_path():
    """프로젝트 루트의 .opensmith/memory-bank/memory.db 경로 반환."""
    project_root = os.getcwd()
    db_dir = os.path.join(project_root, ".opensmith", "memory-bank")
    os.makedirs(db_dir, exist_ok=True)
    return os.path.join(db_dir, "memory.db")

def init_db(db_path):
    """DB 스키마 생성."""
    conn = sqlite3.connect(db_path)

    # sqlite-vec 확장 로드 시도
    vec_loaded = False
    try:
        conn.enable_load_extension(True)
        # 플랫폼별 확장 경로 시도
        for ext in ["vec0", "sqlite_vec", "./vec0", "./sqlite_vec"]:
            try:
                conn.load_extension(ext)
                vec_loaded = True
                break
            except Exception:
                continue

        if not vec_loaded:
            # pip install sqlite-vec 로 설치된 경우
            try:
                import sqlite_vec
                sqlite_vec.load(conn)
                vec_loaded = True
            except ImportError:
                pass
    except Exception:
        pass

    cursor = conn.cursor()

    # ========== exchanges 테이블 (대화 인덱싱) ==========
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS exchanges (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            user_message TEXT NOT NULL,
            assistant_message TEXT NOT NULL,
            tools_used TEXT DEFAULT '[]',
            files_modified TEXT DEFAULT '[]',
            session_id TEXT NOT NULL,
            embedding BLOB
        )
    """)

    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_exchanges_session
        ON exchanges(session_id)
    """)

    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_exchanges_timestamp
        ON exchanges(timestamp)
    """)

    # ========== facts 테이블 (팩트 추출) ==========
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS facts (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL CHECK(type IN ('decision', 'pattern', 'error', 'constraint', 'self-improve')),
            fact TEXT NOT NULL,
            confidence REAL DEFAULT 0.5,
            tags TEXT DEFAULT '[]',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            source_session TEXT,
            version INTEGER DEFAULT 1,
            status TEXT DEFAULT 'active' CHECK(status IN ('active', 'superseded', 'pending')),
            embedding BLOB
        )
    """)

    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_facts_type ON facts(type)
    """)
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_facts_status ON facts(status)
    """)

    # ========== fact_history 테이블 ==========
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS fact_history (
            id TEXT PRIMARY KEY,
            fact_id TEXT REFERENCES facts(id),
            previous_fact TEXT NOT NULL,
            relation TEXT NOT NULL CHECK(relation IN ('CONTRADICTION', 'EVOLUTION')),
            changed_at TEXT NOT NULL
        )
    """)

    # ========== ontology 테이블 ==========
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS ontology (
            id TEXT PRIMARY KEY,
            source_fact_id TEXT REFERENCES facts(id),
            target_fact_id TEXT REFERENCES facts(id),
            relation TEXT NOT NULL CHECK(relation IN ('INFLUENCES', 'SUPPORTS', 'CONTRADICTS', 'REQUIRES')),
            strength REAL DEFAULT 0.5
        )
    """)

    # ========== domains 테이블 ==========
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS domains (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            description TEXT
        )
    """)

    cursor.execute("""
        CREATE TABLE IF NOT EXISTS fact_domains (
            fact_id TEXT REFERENCES facts(id),
            domain_id TEXT REFERENCES domains(id),
            PRIMARY KEY (fact_id, domain_id)
        )
    """)

    # 기본 도메인 시딩
    default_domains = [
        ("backend", "백엔드 관련"),
        ("frontend", "프론트엔드 관련"),
        ("infra", "인프라/배포 관련"),
        ("security", "보안 관련"),
        ("performance", "성능 관련"),
        ("database", "데이터베이스 관련"),
        ("design", "설계/아키텍처 관련"),
    ]
    for domain_id, desc in default_domains:
        cursor.execute(
            "INSERT OR IGNORE INTO domains (id, name, description) VALUES (?, ?, ?)",
            (domain_id, domain_id, desc)
        )

    # ========== FTS 인덱스 ==========
    cursor.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS fts_exchanges USING fts5(
            user_message,
            assistant_message,
            content='exchanges',
            content_rowid='rowid'
        )
    """)

    cursor.execute("""
        CREATE VIRTUAL TABLE IF NOT EXISTS fts_facts USING fts5(
            fact,
            tags,
            content='facts',
            content_rowid='rowid'
        )
    """)

    # FTS 자동 동기화 트리거
    cursor.executescript("""
        CREATE TRIGGER IF NOT EXISTS exchanges_ai AFTER INSERT ON exchanges BEGIN
            INSERT INTO fts_exchanges(rowid, user_message, assistant_message)
            VALUES (new.rowid, new.user_message, new.assistant_message);
        END;

        CREATE TRIGGER IF NOT EXISTS facts_ai AFTER INSERT ON facts BEGIN
            INSERT INTO fts_facts(rowid, fact, tags)
            VALUES (new.rowid, new.fact, new.tags);
        END;

        CREATE TRIGGER IF NOT EXISTS facts_au AFTER UPDATE ON facts BEGIN
            DELETE FROM fts_facts WHERE rowid = old.rowid;
            INSERT INTO fts_facts(rowid, fact, tags)
            VALUES (new.rowid, new.fact, new.tags);
        END;
    """)

    # ========== 벡터 인덱스 (sqlite-vec) ==========
    if vec_loaded:
        try:
            cursor.execute("""
                CREATE VIRTUAL TABLE IF NOT EXISTS vec_exchanges USING vec0(
                    id TEXT PRIMARY KEY,
                    embedding float[384]
                )
            """)
            cursor.execute("""
                CREATE VIRTUAL TABLE IF NOT EXISTS vec_facts USING vec0(
                    id TEXT PRIMARY KEY,
                    embedding float[384]
                )
            """)
            print("[OK] sqlite-vec 벡터 인덱스 생성 완료")
        except Exception as e:
            print(f"[WARN] 벡터 인덱스 생성 실패: {e}")
            vec_loaded = False

    if not vec_loaded:
        print("[WARN] sqlite-vec 미설치. FTS 검색만 가능합니다.")
        print("       벡터 검색을 사용하려면: pip install sqlite-vec")

    conn.commit()

    # 메타데이터 저장
    meta_path = os.path.join(os.path.dirname(db_path), "meta.json")
    meta = {
        "version": "1.0.0",
        "vec_enabled": vec_loaded,
        "embedding_model": "all-MiniLM-L6-v2",
        "embedding_dim": 384,
        "db_path": db_path
    }
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)

    conn.close()
    return vec_loaded

def main():
    db_path = get_db_path()

    if os.path.exists(db_path):
        print(f"[INFO] 기존 DB 발견: {db_path}")
        print("       --force 옵션으로 재생성하거나 그대로 사용합니다.")
        if "--force" not in sys.argv:
            print("[SKIP] 기존 DB 유지")
            return
        os.remove(db_path)
        print("[INFO] 기존 DB 삭제 후 재생성")

    print(f"[INFO] Memory Bank 초기화: {db_path}")
    vec_loaded = init_db(db_path)

    print(f"\n{'='*50}")
    print(f"Memory Bank 초기화 완료!")
    print(f"  DB: {db_path}")
    print(f"  벡터 검색: {'활성' if vec_loaded else '비활성 (FTS만 사용)'}")
    print(f"  임베딩 모델: all-MiniLM-L6-v2 (384-dim)")
    print(f"{'='*50}")

if __name__ == "__main__":
    main()

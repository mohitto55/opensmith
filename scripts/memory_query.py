#!/usr/bin/env python3
"""Memory Bank 하이브리드 검색 (FTS + vec) with RRF."""

import sqlite3
import struct
import json
import os
import sys

DB_PATH = os.path.join(os.getcwd(), ".opensmith", "memory-bank", "memory.db")
META_PATH = os.path.join(os.getcwd(), ".opensmith", "memory-bank", "meta.json")


def db_exists():
    return os.path.exists(DB_PATH)


def get_conn():
    conn = sqlite3.connect(DB_PATH)
    try:
        conn.enable_load_extension(True)
        import sqlite_vec
        sqlite_vec.load(conn)
    except Exception:
        pass
    return conn


def vec_enabled():
    if os.path.exists(META_PATH):
        with open(META_PATH) as f:
            return json.load(f).get("vec_enabled", False)
    return False


def get_top_facts(limit=5):
    if not db_exists():
        print("(Memory Bank 미초기화. /opensmith:init-memory 를 실행하세요)")
        return
    conn = get_conn()
    rows = conn.execute(
        "SELECT type, fact FROM facts WHERE status = 'active' "
        "ORDER BY confidence DESC, updated_at DESC LIMIT ?",
        (limit,)
    ).fetchall()
    conn.close()
    if not rows:
        print("(팩트 없음)")
        return
    for r in rows:
        print(f"{r[0]}|{r[1]}")


def get_pending_improvements(limit=3):
    if not db_exists():
        return
    conn = get_conn()
    rows = conn.execute(
        "SELECT fact FROM facts WHERE type = 'self-improve' AND status = 'pending' "
        "ORDER BY created_at DESC LIMIT ?",
        (limit,)
    ).fetchall()
    conn.close()
    for r in rows:
        print(r[0])


def search_hybrid(query, limit=5, fact_type=None):
    if not db_exists():
        return
    conn = get_conn()

    type_filter = f"AND f.type = '{fact_type}'" if fact_type else ""

    # FTS search
    fts_results = []
    try:
        safe_query = query.replace("'", "''")
        fts_results = conn.execute(f"""
            SELECT f.id, f.type, f.fact, f.confidence
            FROM fts_facts ft
            JOIN facts f ON ft.rowid = f.rowid
            WHERE fts_facts MATCH '{safe_query}'
              AND f.status = 'active'
              {type_filter}
            ORDER BY rank
            LIMIT 20
        """).fetchall()
    except Exception:
        pass

    # Vec search
    vec_results = []
    if vec_enabled():
        try:
            from sentence_transformers import SentenceTransformer
            model = SentenceTransformer("all-MiniLM-L6-v2")
            query_vec = model.encode([query])[0]
            blob = struct.pack(f"{len(query_vec)}f", *query_vec.tolist())

            vec_results = conn.execute(f"""
                SELECT f.id, f.type, f.fact, f.confidence
                FROM vec_facts v
                JOIN facts f ON v.id = f.id
                WHERE f.status = 'active'
                  {type_filter}
                ORDER BY vec_distance_cosine(v.embedding, ?) ASC
                LIMIT 20
            """, (blob,)).fetchall()
        except Exception:
            pass

    conn.close()

    # RRF fusion
    K = 60
    scores = {}
    facts = {}

    for rank, row in enumerate(vec_results):
        fid = row[0]
        scores[fid] = scores.get(fid, 0) + 1.0 / (K + rank + 1)
        facts[fid] = {"type": row[1], "fact": row[2], "conf": row[3]}

    for rank, row in enumerate(fts_results):
        fid = row[0]
        scores[fid] = scores.get(fid, 0) + 1.0 / (K + rank + 1)
        facts[fid] = {"type": row[1], "fact": row[2], "conf": row[3]}

    ranked = sorted(scores.items(), key=lambda x: -x[1])[:limit]
    for fid, score in ranked:
        f = facts[fid]
        print(f"{f['type']}|{f['fact']}|{f['conf']}")


def search_exchanges(query, limit=5):
    """Exchange 검색 (facts가 비어있을 때 대안)."""
    if not db_exists():
        return
    conn = get_conn()

    results = []
    if vec_enabled():
        try:
            from sentence_transformers import SentenceTransformer
            model = SentenceTransformer("all-MiniLM-L6-v2")
            query_vec = model.encode([query])[0]
            blob = struct.pack(f"{len(query_vec)}f", *query_vec.tolist())

            results = conn.execute("""
                SELECT e.user_message, e.assistant_message,
                       vec_distance_cosine(v.embedding, ?) as dist
                FROM vec_exchanges v
                JOIN exchanges e ON v.id = e.id
                ORDER BY dist ASC
                LIMIT ?
            """, (blob, limit)).fetchall()
        except Exception:
            pass

    if not results:
        # FTS fallback
        try:
            safe_query = query.replace("'", "''")
            results = conn.execute(f"""
                SELECT e.user_message, e.assistant_message, 0.0
                FROM fts_exchanges ft
                JOIN exchanges e ON ft.rowid = e.rowid
                WHERE fts_exchanges MATCH '{safe_query}'
                LIMIT {limit}
            """).fetchall()
        except Exception:
            pass

    conn.close()
    for r in results:
        print(f"user: {r[0][:200]}")
        print(f"asst: {r[1][:200]}")
        print()


def main():
    args = sys.argv[1:]
    query = ""
    top_k = 5
    fact_type = None
    mode = "hybrid"  # hybrid | top-facts | pending | exchanges

    i = 0
    while i < len(args):
        if args[i] == "--top-k" and i + 1 < len(args):
            top_k = int(args[i + 1])
            i += 2
        elif args[i] == "--type" and i + 1 < len(args):
            fact_type = args[i + 1]
            i += 2
        elif args[i] == "--top-project-facts":
            mode = "top-facts"
            if i + 1 < len(args) and args[i + 1].isdigit():
                top_k = int(args[i + 1])
                i += 2
            else:
                i += 1
        elif args[i] == "--pending":
            mode = "pending"
            if i + 1 < len(args) and args[i + 1].isdigit():
                top_k = int(args[i + 1])
                i += 2
            else:
                i += 1
        elif args[i] == "--exchanges":
            mode = "exchanges"
            i += 1
        else:
            query += " " + args[i]
            i += 1

    query = query.strip()

    if mode == "top-facts":
        get_top_facts(top_k)
    elif mode == "pending":
        get_pending_improvements(top_k)
    elif mode == "exchanges" and query:
        search_exchanges(query, top_k)
    elif query:
        search_hybrid(query, top_k, fact_type)
    else:
        get_top_facts(top_k)


if __name__ == "__main__":
    main()

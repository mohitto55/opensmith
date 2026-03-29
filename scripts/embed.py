#!/usr/bin/env python3
"""exchange와 fact의 임베딩을 생성하여 DB에 저장합니다."""

import sqlite3
import os
import sys
import json
import struct

def load_model():
    """sentence-transformers 모델 로드."""
    try:
        from sentence_transformers import SentenceTransformer
        print("[INFO] all-MiniLM-L6-v2 모델 로딩 중...")
        model = SentenceTransformer("all-MiniLM-L6-v2")
        print("[OK] 모델 로드 완료")
        return model
    except ImportError:
        print("[ERROR] sentence-transformers가 설치되지 않았습니다.")
        print("        pip install sentence-transformers")
        sys.exit(1)

def float_list_to_blob(floats):
    """float 리스트를 sqlite-vec용 BLOB으로 변환."""
    return struct.pack(f"{len(floats)}f", *floats)

def embed_exchanges(conn, model):
    """임베딩이 없는 exchange에 임베딩 생성."""
    cursor = conn.cursor()
    cursor.execute("SELECT id, user_message, assistant_message FROM exchanges WHERE embedding IS NULL")
    rows = cursor.fetchall()

    if not rows:
        print("[INFO] 임베딩이 필요한 exchange가 없습니다.")
        return 0

    print(f"[INFO] {len(rows)}개 exchange 임베딩 생성 중...")

    # 배치 임베딩
    texts = [f"{row[1]} {row[2]}" for row in rows]
    embeddings = model.encode(texts, show_progress_bar=True, batch_size=32)

    # DB 업데이트
    for i, row in enumerate(rows):
        blob = float_list_to_blob(embeddings[i].tolist())
        cursor.execute("UPDATE exchanges SET embedding = ? WHERE id = ?", (blob, row[0]))

        # vec 테이블에도 삽입 시도
        try:
            cursor.execute(
                "INSERT OR REPLACE INTO vec_exchanges (id, embedding) VALUES (?, ?)",
                (row[0], blob)
            )
        except Exception:
            pass  # vec 테이블이 없으면 스킵

    conn.commit()
    print(f"[OK] {len(rows)}개 exchange 임베딩 완료")
    return len(rows)

def embed_facts(conn, model):
    """임베딩이 없는 fact에 임베딩 생성."""
    cursor = conn.cursor()
    cursor.execute("SELECT id, fact, tags FROM facts WHERE embedding IS NULL")
    rows = cursor.fetchall()

    if not rows:
        print("[INFO] 임베딩이 필요한 fact가 없습니다.")
        return 0

    print(f"[INFO] {len(rows)}개 fact 임베딩 생성 중...")

    texts = [f"{row[1]} {row[2]}" for row in rows]
    embeddings = model.encode(texts, show_progress_bar=True, batch_size=32)

    for i, row in enumerate(rows):
        blob = float_list_to_blob(embeddings[i].tolist())
        cursor.execute("UPDATE facts SET embedding = ? WHERE id = ?", (blob, row[0]))

        try:
            cursor.execute(
                "INSERT OR REPLACE INTO vec_facts (id, embedding) VALUES (?, ?)",
                (row[0], blob)
            )
        except Exception:
            pass

    conn.commit()
    print(f"[OK] {len(rows)}개 fact 임베딩 완료")
    return len(rows)

def embed_query(model, query_text):
    """쿼리 텍스트를 임베딩으로 변환 (memory-query에서 호출용)."""
    embedding = model.encode([query_text])[0]
    blob = float_list_to_blob(embedding.tolist())
    # stdout에 hex로 출력 (bash에서 사용)
    print(blob.hex())

def main():
    db_path = os.path.join(os.getcwd(), ".opensmith", "memory-bank", "memory.db")

    if not os.path.exists(db_path):
        print("[ERROR] Memory Bank DB가 없습니다.")
        sys.exit(1)

    # --query 모드: 쿼리 임베딩만 생성
    if len(sys.argv) >= 3 and sys.argv[1] == "--query":
        model = load_model()
        embed_query(model, " ".join(sys.argv[2:]))
        return

    model = load_model()
    conn = sqlite3.connect(db_path)

    try:
        conn.enable_load_extension(True)
        try:
            import sqlite_vec
            sqlite_vec.load(conn)
        except (ImportError, Exception):
            pass
    except Exception:
        pass

    ex_count = embed_exchanges(conn, model)
    fact_count = embed_facts(conn, model)

    conn.close()
    print(f"\n[완료] exchange: {ex_count}개, fact: {fact_count}개 임베딩 생성")

if __name__ == "__main__":
    main()

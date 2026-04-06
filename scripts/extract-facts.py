#!/usr/bin/env python3
"""세션 대화에서 팩트를 추출하고 Memory Bank에 저장합니다.

fact-extraction.sh 훅에서 호출됩니다.
Haiku API로 대화에서 의사결정/패턴/에러/제약사항을 추출합니다.
"""

import json
import os
import sys
import sqlite3
import hashlib
import struct
from datetime import datetime

def get_recent_conversation(session_file=None):
    """최근 세션 대화를 가져옵니다."""
    if session_file and os.path.exists(session_file):
        with open(session_file, "r", encoding="utf-8") as f:
            return f.read()

    # stdin에서 읽기 (훅에서 파이프로 전달)
    if not sys.stdin.isatty():
        return sys.stdin.read()

    return None

def extract_facts_with_llm(conversation_text):
    """Anthropic API(Haiku)로 팩트 추출."""
    try:
        import anthropic
    except ImportError:
        print("[ERROR] anthropic 패키지가 없습니다: pip install anthropic")
        return []

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("[WARN] ANTHROPIC_API_KEY가 설정되지 않았습니다. 팩트 추출 스킵.")
        return []

    client = anthropic.Anthropic(api_key=api_key)

    # 대화 텍스트가 너무 길면 잘라냄
    max_chars = 50000
    if len(conversation_text) > max_chars:
        conversation_text = conversation_text[-max_chars:]

    prompt = f"""다음 Claude Code 대화에서 미래 세션에 유용한 팩트를 추출하세요.

카테고리:
- decision: 기술/아키텍처 선택과 그 이유
- pattern: 프로젝트의 코딩 패턴/컨벤션
- error: 에러와 해결 방법
- constraint: 프로젝트 제약사항
- self-improve: 개선이 필요한 패턴

각 팩트를 JSON 배열로 반환하세요. 최대 10개:
[{{"type": "decision", "fact": "...", "confidence": 0.8, "tags": ["backend", "mongodb"]}}]

팩트가 없으면 빈 배열 []을 반환하세요.

대화:
{conversation_text}"""

    try:
        response = client.messages.create(
            model="claude-haiku-4-5-20251001",
            max_tokens=2000,
            messages=[{"role": "user", "content": prompt}]
        )

        response_text = response.content[0].text.strip()

        # JSON 배열 추출
        start = response_text.find("[")
        end = response_text.rfind("]") + 1
        if start >= 0 and end > start:
            facts = json.loads(response_text[start:end])
            return facts
        return []
    except Exception as e:
        print(f"[ERROR] 팩트 추출 실패: {e}")
        return []

def consolidate_fact(cursor, new_fact, model=None):
    """새 팩트를 기존 팩트와 비교하여 관계를 결정."""
    # FTS로 유사 팩트 검색
    cursor.execute("""
        SELECT f.id, f.fact, f.confidence, f.version
        FROM fts_facts ft
        JOIN facts f ON ft.rowid = f.rowid
        WHERE fts_facts MATCH ? AND f.status = 'active'
        LIMIT 5
    """, (new_fact["fact"][:100],))

    similar = cursor.fetchall()

    if not similar:
        return "INDEPENDENT", None

    # 간단한 텍스트 유사도로 판단 (임베딩 없이도 동작)
    new_words = set(new_fact["fact"].lower().split())

    for existing in similar:
        existing_words = set(existing[1].lower().split())
        overlap = len(new_words & existing_words)
        union = len(new_words | existing_words)

        if union == 0:
            continue

        jaccard = overlap / union

        if jaccard > 0.8:
            return "DUPLICATE", existing[0]
        elif jaccard > 0.5:
            return "EVOLUTION", existing[0]

    return "INDEPENDENT", None

def save_facts(facts, db_path, session_id="unknown"):
    """팩트를 DB에 저장."""
    if not facts:
        return 0

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    saved = 0
    now = datetime.now().isoformat()

    for fact_data in facts:
        fact_type = fact_data.get("type", "pattern")
        fact_text = fact_data.get("fact", "")
        confidence = fact_data.get("confidence", 0.5)
        tags = json.dumps(fact_data.get("tags", []))

        if not fact_text:
            continue

        fact_id = hashlib.sha256(fact_text.encode()).hexdigest()[:16]

        # 통합 판단
        relation, existing_id = consolidate_fact(cursor, fact_data)

        if relation == "DUPLICATE":
            # 기존 팩트의 confidence 증가
            cursor.execute(
                "UPDATE facts SET confidence = MIN(confidence + 0.1, 1.0), updated_at = ? WHERE id = ?",
                (now, existing_id)
            )
            print(f"  [DUPLICATE] 기존 팩트 강화: {fact_text[:50]}...")

        elif relation == "EVOLUTION":
            # 이전 버전 기록 + 업데이트
            cursor.execute("SELECT fact, version FROM facts WHERE id = ?", (existing_id,))
            old = cursor.fetchone()
            if old:
                history_id = hashlib.sha256(f"{existing_id}_{now}".encode()).hexdigest()[:16]
                cursor.execute(
                    "INSERT OR IGNORE INTO fact_history (id, fact_id, previous_fact, relation, changed_at) VALUES (?, ?, ?, ?, ?)",
                    (history_id, existing_id, old[0], "EVOLUTION", now)
                )
                cursor.execute(
                    "UPDATE facts SET fact = ?, confidence = ?, tags = ?, updated_at = ?, version = version + 1 WHERE id = ?",
                    (fact_text, confidence, tags, now, existing_id)
                )
                print(f"  [EVOLUTION] 팩트 진화: {fact_text[:50]}...")

        else:
            # 새 팩트 삽입
            cursor.execute("""
                INSERT OR IGNORE INTO facts
                (id, type, fact, confidence, tags, created_at, updated_at, source_session, version, status)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 'active')
            """, (fact_id, fact_type, fact_text, confidence, tags, now, now, session_id))

            if cursor.rowcount > 0:
                saved += 1
                print(f"  [NEW] {fact_type}: {fact_text[:50]}...")

    conn.commit()
    conn.close()
    return saved

def save_and_embed(facts, db_path, session_id="unknown"):
    """팩트 저장 후 임베딩도 생성."""
    saved = save_facts(facts, db_path, session_id)
    if saved > 0:
        # 새 팩트에 임베딩 생성
        try:
            from sentence_transformers import SentenceTransformer
            import sqlite_vec

            model = SentenceTransformer("all-MiniLM-L6-v2")
            conn = sqlite3.connect(db_path)
            conn.enable_load_extension(True)
            sqlite_vec.load(conn)

            rows = conn.execute(
                "SELECT id, fact, tags FROM facts WHERE embedding IS NULL"
            ).fetchall()

            for row in rows:
                text = f"{row[1]} {row[2]}"
                embedding = model.encode([text])[0]
                blob = struct.pack(f"{len(embedding)}f", *embedding.tolist())
                conn.execute("UPDATE facts SET embedding = ? WHERE id = ?", (blob, row[0]))
                try:
                    conn.execute(
                        "INSERT OR REPLACE INTO vec_facts (id, embedding) VALUES (?, ?)",
                        (row[0], blob)
                    )
                except Exception:
                    pass

            conn.commit()
            conn.close()
            print(f"[OK] {len(rows)}개 팩트 임베딩 생성")
        except Exception as e:
            print(f"[WARN] 임베딩 생성 스킵: {e}")
    return saved


def main():
    db_path = os.path.join(os.getcwd(), ".opensmith", "memory-bank", "memory.db")

    if not os.path.exists(db_path):
        print("[WARN] Memory Bank DB 없음. 팩트 추출 스킵.")
        sys.exit(0)

    # --save-json 모드: Claude Code에서 직접 JSON을 넘겨서 저장
    if len(sys.argv) >= 3 and sys.argv[1] == "--save-json":
        facts_json = " ".join(sys.argv[2:])
        try:
            facts = json.loads(facts_json)
        except json.JSONDecodeError:
            # stdin에서 읽기 시도
            if not sys.stdin.isatty():
                facts = json.loads(sys.stdin.read())
            else:
                print("[ERROR] JSON 파싱 실패")
                sys.exit(1)

        saved = save_and_embed(facts, db_path)
        print(f"[완료] {saved}개 새 팩트 저장")
        return

    # 기존 모드: 세션 파일 또는 stdin에서 대화 읽기 → LLM 추출
    session_file = sys.argv[1] if len(sys.argv) > 1 else None
    conversation = get_recent_conversation(session_file)

    if not conversation:
        print("[INFO] 대화 내용이 없습니다.")
        sys.exit(0)

    print("[INFO] 팩트 추출 중 (Haiku API)...")
    facts = extract_facts_with_llm(conversation)

    if not facts:
        print("[INFO] 추출된 팩트 없음.")
        sys.exit(0)

    print(f"[INFO] {len(facts)}개 팩트 추출됨. DB 저장 중...")
    saved = save_and_embed(facts, db_path)
    print(f"[완료] {saved}개 새 팩트 저장")

if __name__ == "__main__":
    main()

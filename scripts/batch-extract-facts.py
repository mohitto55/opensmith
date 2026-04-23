#!/usr/bin/env python3
"""배치 팩트 추출 러너.

DB의 exchange를 배치 단위로 읽어 `claude -p`로 팩트를 추출하고 저장한다.
API 키 없이 Claude Code CLI를 서브프로세스로 사용.

Usage:
    python scripts/batch-extract-facts.py --dry-run          # 1배치만
    python scripts/batch-extract-facts.py --batches N        # N배치만
    python scripts/batch-extract-facts.py                    # 전체
"""

import argparse
import json
import os
import sqlite3
import subprocess
import sys
from pathlib import Path

BATCH_SIZE = 30
MIN_CONFIDENCE = 0.7
DB_PATH = Path(".opensmith/memory-bank/memory.db")

SYSTEM_PROMPT = """You are a fact extractor for a project memory bank.
Given a batch of Claude Code conversation exchanges, extract reusable facts.

Extract ONLY these fact types:
- decision: tech/architecture choices with reasoning
- pattern: project-specific coding patterns/conventions
- constraint: project constraints (platform, tooling, policy)
- error: errors encountered and their solutions
- self-improve: patterns needing improvement in scaffolding/pipeline

Rules:
- Output ONLY project-specific facts, NOT general programming knowledge
- confidence must be >= 0.7, else skip the fact
- Prefer Korean for fact text (project language)
- Max 10 facts per batch. Fewer is better than noisy.
- If no strong facts, return empty array [].

Output format: JSON object with "facts" key containing an array. No markdown, no explanation.
Example:
{"facts":[{"type":"decision","fact":"...","confidence":0.85,"tags":["backend","db"]}]}
"""

JSON_SCHEMA = {
    "type": "object",
    "properties": {
        "facts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "type": {"type": "string", "enum": ["decision", "pattern", "constraint", "error", "self-improve"]},
                    "fact": {"type": "string"},
                    "confidence": {"type": "number"},
                    "tags": {"type": "array", "items": {"type": "string"}}
                },
                "required": ["type", "fact", "confidence", "tags"]
            }
        }
    },
    "required": ["facts"]
}


def fetch_exchanges(conn, limit, offset):
    """최근 순으로 exchange 가져오기."""
    rows = conn.execute(
        "SELECT id, timestamp, user_message, assistant_message "
        "FROM exchanges ORDER BY timestamp DESC LIMIT ? OFFSET ?",
        (limit, offset)
    ).fetchall()
    return rows


def format_batch(rows):
    """배치를 프롬프트용 텍스트로."""
    parts = []
    for i, (ex_id, ts, user, asst) in enumerate(rows, 1):
        user = (user or "").strip()[:2000]
        asst = (asst or "").strip()[:2000]
        parts.append(f"--- Exchange {i} ({ts}) ---\nUSER: {user}\nASSISTANT: {asst}")
    return "\n\n".join(parts)


def call_claude(prompt_text, system_prompt):
    """claude -p 호출. prompt는 stdin으로 전달해 CLI 옵션 파싱 충돌 회피.

    - --model haiku: 비용 절감
    - --system-prompt: 기본 CLAUDE.md/툴 프롬프트 제거하고 팩트 추출 전용으로 교체
    """
    cmd = [
        "claude", "-p",
        "--model", "haiku",
        "--system-prompt", system_prompt,
        "--json-schema", json.dumps(JSON_SCHEMA),
        "--output-format", "json",
    ]
    try:
        result = subprocess.run(
            cmd, input=prompt_text, capture_output=True, text=True,
            timeout=180, encoding="utf-8"
        )
    except subprocess.TimeoutExpired:
        return None, "timeout"

    if result.returncode != 0:
        return None, f"exit {result.returncode}: {result.stderr[:500]}"

    try:
        wrapper = json.loads(result.stdout)
        if isinstance(wrapper, dict) and wrapper.get("is_error"):
            return None, f"api error: {wrapper.get('result', '')[:300]}"

        # 1순위: structured_output (json-schema 적용 시)
        so = wrapper.get("structured_output") if isinstance(wrapper, dict) else None
        if isinstance(so, dict) and isinstance(so.get("facts"), list):
            return so["facts"], None

        # 2순위: result 텍스트에서 JSON 추출
        content = wrapper.get("result", "") if isinstance(wrapper, dict) else result.stdout
        start = content.find("{")
        end = content.rfind("}") + 1
        if start >= 0 and end > start:
            try:
                obj = json.loads(content[start:end])
                if isinstance(obj, dict) and isinstance(obj.get("facts"), list):
                    return obj["facts"], None
            except json.JSONDecodeError:
                pass
        return [], None
    except Exception as e:
        return None, f"parse error: {e}; stdout head: {result.stdout[:300]}"


def save_facts(facts, session_tag):
    """배치 저장. id는 fact 텍스트 해시라 INSERT OR IGNORE로 중복 자동 제거.
    임베딩은 전체 완료 후 embed.py로 한 번에 생성.
    """
    if not facts:
        return 0

    import hashlib
    from datetime import datetime

    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    saved = 0
    now = datetime.now().isoformat()

    for fact_data in facts:
        fact_type = fact_data.get("type", "pattern")
        fact_text = (fact_data.get("fact") or "").strip()
        confidence = float(fact_data.get("confidence", 0.5))
        tags = json.dumps(fact_data.get("tags", []), ensure_ascii=False)

        if not fact_text:
            continue

        fact_id = hashlib.sha256(fact_text.encode("utf-8")).hexdigest()[:16]

        cursor.execute("""
            INSERT OR IGNORE INTO facts
            (id, type, fact, confidence, tags, created_at, updated_at, source_session, version, status)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 'active')
        """, (fact_id, fact_type, fact_text, confidence, tags, now, now, session_tag))

        if cursor.rowcount > 0:
            saved += 1
            print(f"    [NEW] {fact_type}: {fact_text[:60]}")
        else:
            print(f"    [DUP] {fact_text[:60]}")

    conn.commit()
    conn.close()
    return saved


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="1배치만 돌리고 종료")
    ap.add_argument("--batches", type=int, help="N배치만 실행")
    ap.add_argument("--offset", type=int, default=0, help="시작 offset")
    args = ap.parse_args()

    if not DB_PATH.exists():
        print(f"[ERROR] DB 없음: {DB_PATH}")
        sys.exit(1)

    conn = sqlite3.connect(DB_PATH)
    total = conn.execute("SELECT COUNT(*) FROM exchanges").fetchone()[0]
    print(f"[INFO] 총 exchange: {total}")

    total_batches = (total + BATCH_SIZE - 1) // BATCH_SIZE
    if args.dry_run:
        total_batches = 1
    elif args.batches:
        total_batches = min(args.batches, total_batches)

    print(f"[INFO] 실행할 배치: {total_batches} (BATCH_SIZE={BATCH_SIZE})")

    saved_total = 0
    skipped_low_conf = 0
    errors = []

    for i in range(total_batches):
        offset = args.offset + i * BATCH_SIZE
        rows = fetch_exchanges(conn, BATCH_SIZE, offset)
        if not rows:
            print(f"[INFO] batch {i+1}: rows 없음, 종료")
            break

        batch_text = format_batch(rows)
        print(f"\n[{i+1}/{total_batches}] exchanges {offset}~{offset+len(rows)-1} ({len(batch_text)} chars) → claude -p ...")

        facts, err = call_claude(batch_text, SYSTEM_PROMPT)
        if err:
            print(f"  [ERROR] {err}")
            errors.append((i, err))
            continue

        if facts is None:
            print("  [ERROR] facts None")
            continue

        if args.dry_run:
            print(f"  [DEBUG] raw facts count: {len(facts)}")
            if facts:
                print(f"  [DEBUG] first fact: {json.dumps(facts[0], ensure_ascii=False)[:200]}")

        # confidence 필터
        before = len(facts)
        facts = [f for f in facts if f.get("confidence", 0) >= MIN_CONFIDENCE]
        skipped_low_conf += before - len(facts)

        print(f"  추출: {before}개, 필터 후: {len(facts)}개")
        for f in facts:
            print(f"    [{f['type']}] conf={f['confidence']:.2f} - {f['fact'][:80]}")

        if args.dry_run:
            print("\n[DRY-RUN] 저장 스킵. 품질 확인 후 --dry-run 빼고 재실행하세요.")
            break

        saved = save_facts(facts, session_tag=f"batch-{i}")
        saved_total += saved

    print(f"\n========== 완료 ==========")
    print(f"저장된 팩트: {saved_total}")
    print(f"confidence < {MIN_CONFIDENCE} 필터됨: {skipped_low_conf}")
    print(f"배치 에러: {len(errors)}")
    if errors:
        for i, e in errors:
            print(f"  batch {i}: {e[:100]}")


if __name__ == "__main__":
    main()

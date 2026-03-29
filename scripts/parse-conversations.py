#!/usr/bin/env python3
"""Claude Code 대화 로그를 파싱하여 exchange 쌍으로 변환하고 DB에 저장합니다."""

import json
import os
import sys
import hashlib
import sqlite3
from datetime import datetime
from pathlib import Path

def find_conversation_files():
    """Claude Code 대화 로그 디렉토리 탐색."""
    claude_dir = Path.home() / ".claude" / "projects"
    if not claude_dir.exists():
        print(f"[WARN] Claude 대화 디렉토리 없음: {claude_dir}")
        return []

    jsonl_files = []
    for project_dir in claude_dir.iterdir():
        if project_dir.is_dir():
            for f in project_dir.glob("*.jsonl"):
                jsonl_files.append(f)

    return sorted(jsonl_files, key=lambda f: f.stat().st_mtime)

def parse_jsonl(file_path):
    """JSONL 파일에서 user/assistant 쌍을 추출."""
    exchanges = []
    messages = []

    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
                messages.append(msg)
            except json.JSONDecodeError:
                continue

    # user/assistant 쌍 매칭
    pending_user = None
    session_id = file_path.stem

    for msg in messages:
        msg_data = msg.get("message", msg)
        role = msg_data.get("role", "")

        if role == "user":
            # user 메시지 추출
            content = msg_data.get("content", "")
            if isinstance(content, list):
                # tool_result 등 복합 content
                text_parts = []
                for part in content:
                    if isinstance(part, dict):
                        if part.get("type") == "text":
                            text_parts.append(part.get("text", ""))
                        elif part.get("type") == "tool_result":
                            pass  # tool result는 스킵
                    elif isinstance(part, str):
                        text_parts.append(part)
                content = " ".join(text_parts)

            if content and len(content.strip()) > 0:
                pending_user = {
                    "content": content.strip(),
                    "timestamp": msg.get("timestamp", datetime.now().isoformat())
                }

        elif role == "assistant" and pending_user:
            # assistant 메시지 추출
            content = msg_data.get("content", "")
            if isinstance(content, list):
                text_parts = []
                tools_used = []
                files_modified = []
                for part in content:
                    if isinstance(part, dict):
                        if part.get("type") == "text":
                            text_parts.append(part.get("text", ""))
                        elif part.get("type") == "tool_use":
                            tool_name = part.get("name", "")
                            tools_used.append(tool_name)
                            # 파일 수정 도구에서 파일 경로 추출
                            tool_input = part.get("input", {})
                            if tool_name in ("Write", "Edit") and "file_path" in tool_input:
                                files_modified.append(tool_input["file_path"])
                content = " ".join(text_parts)
            else:
                tools_used = []
                files_modified = []

            if content and len(content.strip()) > 0:
                exchange_text = f"{pending_user['content']} {content.strip()}"
                exchange_id = hashlib.sha256(exchange_text.encode()).hexdigest()[:16]

                exchanges.append({
                    "id": exchange_id,
                    "timestamp": pending_user["timestamp"],
                    "user_message": pending_user["content"],
                    "assistant_message": content.strip(),
                    "tools_used": json.dumps(tools_used),
                    "files_modified": json.dumps(files_modified),
                    "session_id": session_id,
                })

            pending_user = None

    return exchanges

def save_to_db(exchanges, db_path):
    """exchange를 DB에 저장."""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    inserted = 0
    skipped = 0
    for ex in exchanges:
        try:
            cursor.execute("""
                INSERT OR IGNORE INTO exchanges
                (id, timestamp, user_message, assistant_message, tools_used, files_modified, session_id)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                ex["id"], ex["timestamp"], ex["user_message"],
                ex["assistant_message"], ex["tools_used"],
                ex["files_modified"], ex["session_id"]
            ))
            if cursor.rowcount > 0:
                inserted += 1
            else:
                skipped += 1
        except Exception as e:
            print(f"[WARN] 저장 실패: {e}")
            skipped += 1

    conn.commit()
    conn.close()
    return inserted, skipped

def main():
    db_path = os.path.join(os.getcwd(), ".opensmith", "memory-bank", "memory.db")

    if not os.path.exists(db_path):
        print("[ERROR] Memory Bank DB가 없습니다. 먼저 init-db.py를 실행하세요.")
        sys.exit(1)

    print("[INFO] Claude Code 대화 로그 검색 중...")
    files = find_conversation_files()

    if not files:
        print("[INFO] 대화 로그가 없습니다.")
        return

    print(f"[INFO] {len(files)}개 대화 파일 발견")

    total_inserted = 0
    total_skipped = 0

    for f in files:
        exchanges = parse_jsonl(f)
        if exchanges:
            inserted, skipped = save_to_db(exchanges, db_path)
            total_inserted += inserted
            total_skipped += skipped
            if inserted > 0:
                print(f"  {f.name}: {inserted}개 저장, {skipped}개 스킵")

    print(f"\n[완료] 총 {total_inserted}개 exchange 저장, {total_skipped}개 스킵")

if __name__ == "__main__":
    main()

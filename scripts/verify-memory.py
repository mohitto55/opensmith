#!/usr/bin/env python3
"""Memory Bank 검증 스크립트.

현재 프로젝트 DB의 상태와 프로젝트 격리 여부를 점검한다.
init-memory 스킬의 검증 단계에서 호출.
"""

import sqlite3
import sys
from pathlib import Path


def cwd_to_slug() -> str:
    return (
        str(Path.cwd().resolve())
        .replace("\\", "/")
        .replace("/", "-")
        .replace(":", "-")
        .strip("-")
    )


def main():
    db_path = Path(".opensmith/memory-bank/memory.db")
    if not db_path.exists():
        print(f"[ERROR] DB 없음: {db_path}")
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    n_ex = conn.execute("SELECT COUNT(*) FROM exchanges").fetchone()[0]
    n_ex_noemb = conn.execute("SELECT COUNT(*) FROM exchanges WHERE embedding IS NULL").fetchone()[0]
    n_fact = conn.execute("SELECT COUNT(*) FROM facts").fetchone()[0]
    n_fact_noemb = conn.execute("SELECT COUNT(*) FROM facts WHERE embedding IS NULL").fetchone()[0]

    cwd_slug = cwd_to_slug()
    proj_dir = Path.home() / ".claude" / "projects" / cwd_slug
    ok = {f.stem for f in proj_dir.glob("*.jsonl")} if proj_dir.exists() else set()
    db_sessions = {r[0] for r in conn.execute("SELECT DISTINCT session_id FROM exchanges")}
    foreign = db_sessions - ok

    print(f"Project slug : {cwd_slug}")
    print(f"JSONL files  : {len(ok)}")
    print(f"DB sessions  : {len(db_sessions)}")
    print(f"Foreign      : {len(foreign)}  (0이어야 정화됨)")
    print()
    print(f"Exchanges    : {n_ex}  (임베딩 없음: {n_ex_noemb})")
    print(f"Facts        : {n_fact}  (임베딩 없음: {n_fact_noemb})")

    # 종합 판정
    issues = []
    if len(foreign) > 0:
        issues.append(f"타 프로젝트 session {len(foreign)}개 혼입 → init-db.py --force 후 재실행 권장")
    if n_ex == 0:
        issues.append("Exchange 0개 → parse-conversations.py 실행 필요")
    if n_ex_noemb > 0 or n_fact_noemb > 0:
        issues.append(f"임베딩 누락(exchange {n_ex_noemb}, facts {n_fact_noemb}) → embed.py 실행 필요")

    print()
    if issues:
        print("[문제]")
        for i in issues:
            print(f"  - {i}")
        sys.exit(2)
    else:
        print("[OK] 모든 검증 통과")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Phase state updater. Called by skills to track pipeline progress.

Usage:
  python update_phase.py <session_id> <pipeline> <phase> <status>

Examples:
  python update_phase.py abc123 execute step0 in_progress
  python update_phase.py abc123 execute step0 completed
  python update_phase.py abc123 agent-teams phase2 in_progress
  python update_phase.py abc123 execute done completed    # pipeline finished
  python update_phase.py abc123 clear                     # remove state file

State file: .opensmith/states/state-{session_id}.json
"""

import json
import sys
import os


def get_states_dir() -> str:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    return os.path.join(project_dir, ".opensmith", "states")


def get_state_path(session_id: str) -> str:
    return os.path.join(get_states_dir(), f"state-{session_id}.json")


def main():
    if len(sys.argv) < 3:
        print("Usage: update_phase.py <session_id> <pipeline> <phase> <status>", file=sys.stderr)
        print("       update_phase.py <session_id> clear", file=sys.stderr)
        sys.exit(1)

    session_id = sys.argv[1]

    # Handle clear command
    if sys.argv[2] == "clear":
        path = get_state_path(session_id)
        if os.path.exists(path):
            os.remove(path)
            print(f"Cleared state for session {session_id}")
        sys.exit(0)

    if len(sys.argv) < 5:
        print("Usage: update_phase.py <session_id> <pipeline> <phase> <status>", file=sys.stderr)
        sys.exit(1)

    pipeline = sys.argv[2]   # "execute" or "agent-teams"
    phase = sys.argv[3]      # e.g. "step3", "phase2", "done"
    status = sys.argv[4]     # "in_progress" or "completed"

    # Ensure states directory exists
    states_dir = get_states_dir()
    os.makedirs(states_dir, exist_ok=True)

    # Read existing state or create new
    state_path = get_state_path(session_id)
    if os.path.exists(state_path):
        with open(state_path, "r", encoding="utf-8") as f:
            state = json.load(f)
    else:
        state = {"history": []}

    # Update state
    state["pipeline"] = pipeline
    state["current"] = phase
    state["status"] = status

    # Track history
    if "history" not in state:
        state["history"] = []
    state["history"].append({
        "pipeline": pipeline,
        "phase": phase,
        "status": status,
    })

    # Write state
    with open(state_path, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)

    print(f"Updated: {pipeline}/{phase} → {status}")


if __name__ == "__main__":
    main()

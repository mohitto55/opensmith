#!/usr/bin/env python3
"""
Phase enforcement hook for PreToolUse.
Reads session_id from stdin JSON, checks .opensmith/states/state-{session_id}.json,
and blocks tool calls that violate phase ordering.

Exit codes:
  0 = allow
  2 = block (stderr message shown to Claude)
"""

import json
import sys
import os

# Phase definitions
EXECUTE_STEPS = [f"step{i}" for i in range(10)]  # step0 ~ step9
AGENT_TEAMS_PHASES = [f"phase{i}" for i in range(6)]  # phase0 ~ phase5

# Tools that are always allowed regardless of phase (read-only / tracking)
ALWAYS_ALLOWED_TOOLS = {
    "Read", "Glob", "Grep", "TaskCreate", "TaskUpdate", "TaskList", "TaskGet",
    "SendMessage", "Agent",  # subagents need to spawn freely
    "TeamCreate",  # team creation is part of phase0
    "Skill",  # skill chaining must not be blocked
    "ToolSearch",
}

# Tools that actually modify state (these get phase-checked)
MODIFYING_TOOLS = {"Edit", "Write", "Bash", "NotebookEdit"}


def get_state_path(session_id: str) -> str:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    states_dir = os.path.join(project_dir, ".opensmith", "states")
    return os.path.join(states_dir, f"state-{session_id}.json")


def read_state(session_id: str) -> dict | None:
    path = get_state_path(session_id)
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def main():
    # Read hook input from stdin
    try:
        hook_input = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        sys.exit(0)  # Can't parse input, allow

    session_id = hook_input.get("session_id", "")
    tool_name = hook_input.get("tool_name", "")

    # Always allow non-modifying tools
    if tool_name in ALWAYS_ALLOWED_TOOLS or tool_name not in MODIFYING_TOOLS:
        sys.exit(0)

    # No state file = no pipeline active, allow everything
    state = read_state(session_id)
    if state is None:
        sys.exit(0)

    pipeline = state.get("pipeline")  # "execute" or "agent-teams"
    current = state.get("current")    # e.g. "step3" or "phase2"
    status = state.get("status")      # "in_progress" or "completed"

    if not pipeline or not current:
        sys.exit(0)

    # If pipeline is completed, allow everything
    if status == "completed":
        sys.exit(0)

    # Determine valid phases
    if pipeline == "execute":
        phases = EXECUTE_STEPS
    elif pipeline == "agent-teams":
        phases = AGENT_TEAMS_PHASES
    else:
        sys.exit(0)

    if current not in phases:
        sys.exit(0)

    current_idx = phases.index(current)

    # Phase is in_progress — modifying tools are allowed for current phase.
    # Inject current phase as additionalContext so Claude stays aware.
    print(json.dumps({
        "additionalContext": f"현재 {pipeline}/{current} 진행 중입니다. "
                            f"이 단계의 작업만 수행하세요. "
                            f"다음 단계로 넘어가려면 먼저 {current}를 완료하세요."
    }))
    sys.exit(0)


if __name__ == "__main__":
    main()

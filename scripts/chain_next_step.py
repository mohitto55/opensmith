#!/usr/bin/env python3
"""
Chain hook for TaskCompleted event.
Reads session state, advances to next step, and injects additionalContext
telling Claude which step file to read next.

Exit codes:
  0 = success (additionalContext injected or no pipeline active)
"""

import json
import sys
import os

EXECUTE_STEPS = [f"step{i}" for i in range(10)]  # step0 ~ step9
AGENT_TEAMS_PHASES = [f"phase{i}" for i in range(6)]  # phase0 ~ phase5

STEP_FILES = {
    f"step{i}": f"skills/execute/steps/step{i}-{name}.md"
    for i, name in enumerate([
        "read-prd", "feature-prd", "collect", "design",
        "approve", "implement", "build", "qa", "deploy", "report"
    ])
}


def get_state_path(session_id: str) -> str:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    return os.path.join(project_dir, ".opensmith", "states", f"state-{session_id}.json")


def read_state(session_id: str) -> dict | None:
    path = get_state_path(session_id)
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def write_state(session_id: str, state: dict):
    path = get_state_path(session_id)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def main():
    try:
        hook_input = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, Exception):
        sys.exit(0)

    session_id = hook_input.get("session_id", "")
    if not session_id:
        sys.exit(0)

    state = read_state(session_id)
    if state is None:
        sys.exit(0)

    pipeline = state.get("pipeline")
    current = state.get("current")
    status = state.get("status")

    if not pipeline or not current or status != "in_progress":
        sys.exit(0)

    # Determine phase list
    if pipeline == "execute":
        phases = EXECUTE_STEPS
    elif pipeline == "agent-teams":
        phases = AGENT_TEAMS_PHASES
    else:
        sys.exit(0)

    if current not in phases:
        sys.exit(0)

    current_idx = phases.index(current)

    # Advance to next step
    if current_idx + 1 < len(phases):
        next_phase = phases[current_idx + 1]

        # Update state
        state["current"] = next_phase
        state["status"] = "in_progress"
        if "history" not in state:
            state["history"] = []
        state["history"].append({
            "pipeline": pipeline,
            "phase": next_phase,
            "status": "in_progress",
        })
        write_state(session_id, state)

        # Build additionalContext
        if pipeline == "execute" and next_phase in STEP_FILES:
            step_file = STEP_FILES[next_phase]
            print(json.dumps({
                "additionalContext": (
                    f"{current} 완료. 다음: {next_phase}. "
                    f"반드시 `{step_file}` 를 Read하고 지시를 따르세요."
                )
            }))
        else:
            print(json.dumps({
                "additionalContext": f"{current} 완료. 다음: {next_phase} 진행하세요."
            }))
    else:
        # Pipeline finished
        state["status"] = "completed"
        state["current"] = "done"
        if "history" not in state:
            state["history"] = []
        state["history"].append({
            "pipeline": pipeline,
            "phase": "done",
            "status": "completed",
        })
        write_state(session_id, state)

        print(json.dumps({
            "additionalContext": f"{pipeline} 파이프라인 완료. 모든 스텝이 끝났습니다."
        }))

    sys.exit(0)


if __name__ == "__main__":
    main()

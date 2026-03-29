# LoopyEra -- Autonomous Self-Improving Development Architecture for Claude Code

LoopyEra is a template system that turns Claude Code into an autonomous,
self-improving development agent. It wraps every Claude Code session in a
layered hook architecture that **validates, guards, advises, and learns** from
every action the agent takes.

The system was extracted from a production project (CrackCopy) and packaged as
a reusable template so any team can adopt the same architecture.

---

## Core Concept: The 5-Layer Architecture

```
Layer 1 -- User         Prompts, slash commands, intent
Layer 2 -- Claude        LLM reasoning, tool use, code generation
Layer 3 -- Hooks         Automated gates that intercept every tool call
Layer 4 -- Memory        Facts, metrics, session continuity, self-improvement
Layer 5 -- Infrastructure  Build, deploy, monitor, rollback
```

**Hooks** are the heart of the system. They fire at four lifecycle points:

| Event          | When it fires                                  | Typical use                        |
|----------------|------------------------------------------------|------------------------------------|
| `SessionStart` | Once when a Claude Code session begins         | Inject context, check worktree     |
| `PreToolUse`   | Before Claude writes or edits a file           | Block forbidden patterns (HARD)    |
| `PostToolUse`  | After Claude writes or edits a file            | Warn about style / suggest fixes   |
| `Stop`         | When Claude finishes responding                | Extract facts, log metrics, commit |

Hooks are classified into three escalation tiers:

| Tier    | Behavior                                                        |
|---------|-----------------------------------------------------------------|
| **HARD**  | Blocks the action entirely if the check fails (exit code 2)  |
| **AGENT** | Automatically fixes the problem and retries                   |
| **SOFT**  | Prints a warning or suggestion; does not block                |

---

## Directory Structure

```
loopy-era/
  README.md                   # This file
  config.example.yaml         # Example configuration values
  setup.sh                    # Automated installer script
  settings.template.json      # .claude/settings.json template
  CLAUDE.template.md          # CLAUDE.md template for your project
  docs/                       # Architecture deep-dives (optional reading)
  hooks/                      # Hook scripts (copied to .claude/hooks/)
    hard/
      scaffold-never-do.sh    # Block forbidden code patterns
      security-gate.sh        # Block secrets and insecure patterns
      import-guard.sh         # Block banned imports / dependencies
      file-size-guard.sh      # Block files exceeding line limit
      typecheck-gate.sh       # Block on type errors
      lint-gate.sh            # Block on lint errors
      test-coverage-gate.sh   # Block if coverage drops
      docs-structure-gate.sh  # Block malformed doc changes
    agent/
      scaffold-fix-agent.sh   # Auto-fix scaffold violations
      type-fix-agent.sh       # Auto-fix type errors
      build-fix-agent.sh      # Auto-fix build failures
      test-fix-agent.sh       # Auto-fix failing tests
      deploy-fix-agent.sh     # Auto-fix deploy issues
      merge-conflict-agent.sh # Auto-resolve merge conflicts
    soft/
      inject-context.sh       # Load project context at session start
      self-improve-check.sh   # Check for pending self-improvements
      session-continuity.sh   # Resume from last session state
      worktree-status.sh      # Report git worktree status
      component-pattern.sh    # Suggest component best practices
      api-consistency.sh      # Warn about API naming inconsistencies
      db-schema-warn.sh       # Warn about schema changes
      perf-hint.sh            # Suggest performance improvements
      fact-extraction.sh      # Extract learnings at session end
      metrics-log.sh          # Log session metrics
      wip-commit.sh           # Auto-commit work in progress
      change-summary.sh       # Summarize changes made
      dependency-alert.sh     # Warn about new dependencies
      deploy-checklist.sh     # Show deploy reminders
      error-pattern-warn.sh   # Warn about known error patterns
      telegram-notify.sh      # Send notifications (optional)
  skills/                     # Skill definitions (copied to .claude/skills/)
    frontend-patterns.md      # Frontend coding standards
    backend-patterns.md       # Backend coding standards
    never-do.md               # Unified list of forbidden patterns
```

---

## Quick Start

### Prerequisites

- Claude Code CLI installed and authenticated
- Bash (Git Bash on Windows, native on macOS/Linux)
- `yq` (optional, for YAML config parsing -- the script falls back to arguments)

### Step 1: Clone or copy this template

```bash
git clone <this-repo> loopy-era
```

### Step 2: Create your configuration

```bash
cp loopy-era/config.example.yaml my-project-config.yaml
# Edit my-project-config.yaml with your project values
```

### Step 3: Run the installer

```bash
cd /path/to/your-project
bash /path/to/loopy-era/setup.sh --config /path/to/my-project-config.yaml
```

Or pass values directly:

```bash
bash /path/to/loopy-era/setup.sh \
  --project-name "MyApp" \
  --project-dir "/path/to/your-project" \
  --frontend-framework "Next.js 14" \
  --backend-framework "ASP.NET Core 8.0" \
  --database "PostgreSQL" \
  --auth-method "JWT + OAuth 2.0" \
  --infra "AWS EKS" \
  --ai-services "Claude API"
```

### Step 4: Review generated files

The installer creates or updates:

- `.claude/settings.json` -- Hook registrations
- `.claude/hooks/` -- All hook scripts
- `.claude/skills/` -- Scaffold pattern files
- `CLAUDE.md` -- Project instructions for Claude Code

### Step 5: Start Claude Code

```bash
claude
```

Every session now runs through the LoopyEra hook pipeline automatically.

---

## Placeholder Reference

These placeholders appear in the template files. The `setup.sh` script
replaces them with your actual values.

| Placeholder                     | Description                                        | Example                                    |
|---------------------------------|----------------------------------------------------|--------------------------------------------|
| `{{PROJECT_NAME}}`              | Display name of your project                       | `MyApp`                                    |
| `{{PROJECT_DIR}}`               | Absolute path to project root                      | `/home/user/myapp`                         |
| `{{PROJECT_DESCRIPTION}}`       | One-line project description                       | `Real-time collaborative editor`           |
| `{{PROJECT_DESCRIPTION_LONG}}`  | Detailed project description (2-3 sentences)       | `A web app that lets teams...`             |
| `{{FRONTEND_FRAMEWORK}}`        | Frontend framework and version                     | `Next.js 14`                               |
| `{{FRONTEND_BUILD_CMD}}`        | Command to build the frontend                      | `cd frontend && npm run build`             |
| `{{FRONTEND_DEV_CMD}}`          | Command to start frontend dev server               | `cd frontend && npm run dev`               |
| `{{FRONTEND_TYPECHECK_CMD}}`    | Command to type-check frontend                     | `cd frontend && npx tsc --noEmit`          |
| `{{BACKEND_FRAMEWORK}}`         | Backend framework and version                      | `ASP.NET Core 8.0`                         |
| `{{BACKEND_BUILD_CMD}}`         | Command to build the backend                       | `cd backend && dotnet build`               |
| `{{BACKEND_DEV_CMD}}`           | Command to start backend dev server                | `cd backend && dotnet run`                 |
| `{{DATABASE}}`                  | Database technology                                | `PostgreSQL 16`                            |
| `{{AUTH_METHOD}}`               | Authentication method                              | `JWT + Google OAuth 2.0`                   |
| `{{INFRA}}`                     | Infrastructure / hosting                           | `AWS EKS + Terraform`                      |
| `{{AI_SERVICES}}`               | AI/ML services used                                | `Claude API + Embeddings`                  |
| `{{DEPLOY_BACKEND_CMD}}`        | Backend deploy command                             | `kubectl rollout restart deploy/backend`   |
| `{{DEPLOY_FRONTEND_CMD}}`       | Frontend deploy command                            | `kubectl rollout restart deploy/frontend`  |
| `{{FRONTEND_NEVER_DO}}`         | Forbidden frontend patterns (multi-line)           | `- Tailwind -> use CSS modules`            |
| `{{BACKEND_NEVER_DO}}`          | Forbidden backend patterns (multi-line)            | `- Controllers -> use Minimal API`         |
| `{{MAX_FILE_LINES}}`            | Maximum lines per file before guard triggers       | `500`                                      |
| `{{BANNED_IMPORTS}}`            | Comma-separated list of banned import patterns     | `tailwindcss,moment`                       |

---

## How to Customize

### Adding a new HARD hook

1. Create a script in `hooks/hard/my-check.sh`
2. The script receives `$TOOL_INPUT` as its first argument
3. Exit with code `2` to block the action, code `0` to allow
4. Print a message to stdout explaining why the action was blocked
5. Register the hook in `settings.template.json` under `PreToolUse`

### Adding a new SOFT hook

1. Create a script in `hooks/soft/my-hint.sh`
2. Exit with code `0` always (soft hooks never block)
3. Print suggestions or warnings to stdout
4. Register in `settings.template.json` under `PostToolUse` or `Stop`

### Adding a new AGENT hook

1. Create a script in `hooks/agent/my-fixer.sh`
2. The script should attempt to fix the issue automatically
3. Exit `0` on success, non-zero if it could not fix
4. Register in `settings.template.json` under `PostToolUse`

### Disabling a hook

Remove or comment out its entry in `.claude/settings.json`. The hook script
can remain on disk without effect.

### Adding custom skills

Place `.md` files in `skills/` and reference them from `CLAUDE.template.md`.
Skills provide domain-specific instructions that Claude reads when invoked.

---

## How It Works at Runtime

```
User sends message
  |
  v
[SessionStart hooks fire]
  - inject-context.sh loads CLAUDE.md + recent facts
  - session-continuity.sh restores last session state
  - worktree-status.sh reports branch/worktree info
  |
  v
Claude reasons and decides to write/edit a file
  |
  v
[PreToolUse hooks fire on Write|Edit]
  - scaffold-never-do.sh checks forbidden patterns  --> BLOCK if violated
  - security-gate.sh checks for secrets/tokens       --> BLOCK if found
  - import-guard.sh checks banned imports             --> BLOCK if found
  - file-size-guard.sh checks line count              --> BLOCK if too large
  |
  v
Claude writes the file
  |
  v
[PostToolUse hooks fire on Write|Edit]
  - component-pattern.sh suggests improvements        --> WARN
  - api-consistency.sh checks naming conventions      --> WARN
  - db-schema-warn.sh flags schema changes            --> WARN
  - perf-hint.sh suggests optimizations               --> WARN
  - scaffold-fix-agent.sh auto-fixes violations       --> AUTO-FIX
  - type-fix-agent.sh auto-fixes type errors          --> AUTO-FIX
  |
  v
Claude finishes responding
  |
  v
[Stop hooks fire]
  - fact-extraction.sh saves learnings to memory
  - metrics-log.sh logs session statistics
  - wip-commit.sh commits work in progress
```

---

## License

This template is provided as-is. Adapt it to your needs.

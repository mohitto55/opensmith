# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Project Overview

**{{PROJECT_NAME}}** -- {{PROJECT_DESCRIPTION}}

{{PROJECT_DESCRIPTION_LONG}}

---

## Build & Test Commands

### Frontend
```bash
{{FRONTEND_BUILD_CMD}}          # Production build
{{FRONTEND_DEV_CMD}}            # Dev server
{{FRONTEND_TYPECHECK_CMD}}      # Type check only
```

### Backend
```bash
{{BACKEND_BUILD_CMD}}           # Build
{{BACKEND_DEV_CMD}}             # Dev server
```

### Deploy
```bash
# Backend deploy
{{DEPLOY_BACKEND_CMD}}

# Frontend deploy
{{DEPLOY_FRONTEND_CMD}}
```

---

## Tech Stack

| Area       | Technology              |
|------------|-------------------------|
| Frontend   | {{FRONTEND_FRAMEWORK}}  |
| Backend    | {{BACKEND_FRAMEWORK}}   |
| Database   | {{DATABASE}}            |
| Auth       | {{AUTH_METHOD}}         |
| Infra      | {{INFRA}}              |
| AI         | {{AI_SERVICES}}        |

---

## Scaffold Patterns (Required Reading)

Before writing any code, review these files:

- **Frontend patterns**: `.claude/skills/frontend-patterns.md`
- **Backend patterns**: `.claude/skills/backend-patterns.md`
- **Forbidden rules**: `.claude/skills/never-do.md`

### Key NEVER DO Rules (Inline Summary)

**Frontend**:
{{FRONTEND_NEVER_DO}}

**Backend**:
{{BACKEND_NEVER_DO}}

---

## Claude's Role

### LoopyEra Architecture

This project uses the **LoopyEra autonomous self-improving architecture**.

- **5 layers**: User -> Claude -> Hooks -> Memory -> Infrastructure
- **Self-improving loop**: Write code -> Validate -> Fix -> Deploy -> Learn -> Reinforce
- **30 hooks**: HARD gates + AGENT auto-fix + SOFT guidance
- **3-tier escalation**: Soft warning -> Agent auto-fix -> Hard block

### Responsibilities

1. **System architecture design and validation** -- infrastructure, auth, scalability
2. **Feature development** -- implement features following scaffold patterns
3. **Documentation management** -- keep docs and code in sync
4. **Code review and optimization** -- quality, performance, security

---

## Skills & Commands

### Development
| Skill           | Description                           |
|-----------------|---------------------------------------|
| `/agent-teams`  | Multi-agent team collaboration        |
| `/dev-cycle`    | Full dev cycle (dev->build->deploy->QA) |
| `/deploy`       | Deploy to infrastructure              |

### Validation
| Skill                      | Description                        |
|----------------------------|------------------------------------|
| `system-design-validator`  | Multi-stage system design review   |
| `secure-web-saas`          | SaaS security checklist            |

### Scaffold
| File                    | Description                  |
|-------------------------|------------------------------|
| `frontend-patterns.md`  | Frontend coding patterns     |
| `backend-patterns.md`   | Backend coding patterns      |
| `never-do.md`           | Unified forbidden rules      |

---

## Project Structure

```
{{PROJECT_NAME}}/
+-- CLAUDE.md                              # This file (base layer)
+-- docs/                                  # Project documentation
+-- .claude/
|   +-- settings.json                      # Hook registrations
|   +-- skills/                            # Scaffold patterns + skills
|   |   +-- frontend-patterns.md
|   |   +-- backend-patterns.md
|   |   +-- never-do.md
|   +-- hooks/                             # LoopyEra automated hooks
|       +-- hard/                          # Blocking gates
|       +-- agent/                         # Auto-fix agents
|       +-- soft/                          # Warnings and suggestions
```

---

## Development Workflow

### Feature Development
1. Check `docs/` for requirements
2. Review scaffold patterns in `frontend-patterns.md`, `backend-patterns.md`
3. Use `/agent-teams` for parallel frontend/backend development
4. Build verification -> Deploy -> QA

### Design Validation
```
"Validate the current architecture with system-design-validator"
```

### Full Cycle
```
/dev-cycle Add user profile feature
```

---

## Important Notes

1. **Security**: Manage JWT tokens, OAuth secrets, and sensitive values via environment variables
2. **Performance**: Always consider QPS calculations and caching strategy
3. **Scalability**: Design with sharding and load balancing in mind
4. **Consistency**: Keep documentation and code in sync
5. **Scaffold compliance**: Always check pattern files before writing code

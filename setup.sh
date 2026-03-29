#!/usr/bin/env bash
# LoopyEra Setup Script
# Installs the LoopyEra hook architecture into a target project.
#
# Usage:
#   bash setup.sh --config config.yaml
#   bash setup.sh --project-name "MyApp" --project-dir "/path/to/project" ...
#
# Requirements: bash 4+, sed, cp
# Optional: yq (for YAML config parsing)

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_NAME=""
PROJECT_DIR=""
PROJECT_DESCRIPTION=""
PROJECT_DESCRIPTION_LONG=""
FRONTEND_FRAMEWORK=""
FRONTEND_BUILD_CMD=""
FRONTEND_DEV_CMD=""
FRONTEND_TYPECHECK_CMD=""
BACKEND_FRAMEWORK=""
BACKEND_BUILD_CMD=""
BACKEND_DEV_CMD=""
DATABASE=""
AUTH_METHOD=""
INFRA=""
AI_SERVICES=""
DEPLOY_BACKEND_CMD=""
DEPLOY_FRONTEND_CMD=""
FRONTEND_NEVER_DO=""
BACKEND_NEVER_DO=""
MAX_FILE_LINES="500"
BANNED_IMPORTS=""
CONFIG_FILE=""
DRY_RUN=false

# ---------------------------------------------------------------------------
# Color output helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
fatal() { error "$@"; exit 1; }

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<'USAGE'
LoopyEra Setup Script

Usage:
  setup.sh --config <config.yaml>
  setup.sh [OPTIONS]

Options:
  --config <file>               Read configuration from YAML file (requires yq)
  --project-name <name>         Project display name (required)
  --project-dir <path>          Absolute path to project root (required)
  --project-description <text>  One-line project description
  --project-description-long <text>  Detailed description (2-3 sentences)
  --frontend-framework <name>   e.g. "Next.js 14"
  --frontend-build-cmd <cmd>    e.g. "cd frontend && npm run build"
  --frontend-dev-cmd <cmd>      e.g. "cd frontend && npm run dev"
  --frontend-typecheck-cmd <cmd> e.g. "cd frontend && npx tsc --noEmit"
  --backend-framework <name>    e.g. "ASP.NET Core 8.0"
  --backend-build-cmd <cmd>     e.g. "cd backend && dotnet build"
  --backend-dev-cmd <cmd>       e.g. "cd backend && dotnet run"
  --database <name>             e.g. "PostgreSQL 16"
  --auth-method <method>        e.g. "JWT + OAuth 2.0"
  --infra <infra>               e.g. "AWS EKS + Terraform"
  --ai-services <services>      e.g. "Claude API"
  --deploy-backend-cmd <cmd>    Backend deploy command
  --deploy-frontend-cmd <cmd>   Frontend deploy command
  --frontend-never-do <rules>   Forbidden frontend patterns (newline-separated)
  --backend-never-do <rules>    Forbidden backend patterns (newline-separated)
  --max-file-lines <number>     Max lines per file (default: 500)
  --banned-imports <list>       Comma-separated banned import patterns
  --dry-run                     Show what would be done without writing files
  --help                        Show this help message

Examples:
  bash setup.sh --config my-project.yaml
  bash setup.sh --project-name "MyApp" --project-dir "/home/user/myapp" \
    --frontend-framework "Next.js 14" --backend-framework "FastAPI"
USAGE
  exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --config)               CONFIG_FILE="$2"; shift 2 ;;
      --project-name)         PROJECT_NAME="$2"; shift 2 ;;
      --project-dir)          PROJECT_DIR="$2"; shift 2 ;;
      --project-description)  PROJECT_DESCRIPTION="$2"; shift 2 ;;
      --project-description-long) PROJECT_DESCRIPTION_LONG="$2"; shift 2 ;;
      --frontend-framework)   FRONTEND_FRAMEWORK="$2"; shift 2 ;;
      --frontend-build-cmd)   FRONTEND_BUILD_CMD="$2"; shift 2 ;;
      --frontend-dev-cmd)     FRONTEND_DEV_CMD="$2"; shift 2 ;;
      --frontend-typecheck-cmd) FRONTEND_TYPECHECK_CMD="$2"; shift 2 ;;
      --backend-framework)    BACKEND_FRAMEWORK="$2"; shift 2 ;;
      --backend-build-cmd)    BACKEND_BUILD_CMD="$2"; shift 2 ;;
      --backend-dev-cmd)      BACKEND_DEV_CMD="$2"; shift 2 ;;
      --database)             DATABASE="$2"; shift 2 ;;
      --auth-method)          AUTH_METHOD="$2"; shift 2 ;;
      --infra)                INFRA="$2"; shift 2 ;;
      --ai-services)          AI_SERVICES="$2"; shift 2 ;;
      --deploy-backend-cmd)   DEPLOY_BACKEND_CMD="$2"; shift 2 ;;
      --deploy-frontend-cmd)  DEPLOY_FRONTEND_CMD="$2"; shift 2 ;;
      --frontend-never-do)    FRONTEND_NEVER_DO="$2"; shift 2 ;;
      --backend-never-do)     BACKEND_NEVER_DO="$2"; shift 2 ;;
      --max-file-lines)       MAX_FILE_LINES="$2"; shift 2 ;;
      --banned-imports)       BANNED_IMPORTS="$2"; shift 2 ;;
      --dry-run)              DRY_RUN=true; shift ;;
      --help|-h)              usage ;;
      *) fatal "Unknown option: $1. Use --help for usage." ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Load YAML config (requires yq)
# ---------------------------------------------------------------------------
load_yaml_config() {
  local cfg="$1"

  if [[ ! -f "$cfg" ]]; then
    fatal "Config file not found: $cfg"
  fi

  if ! command -v yq &>/dev/null; then
    fatal "yq is required to parse YAML config files. Install: https://github.com/mikefarah/yq"
  fi

  info "Loading config from $cfg"

  yq_get() { yq -r "$1 // \"\"" "$cfg" 2>/dev/null || echo ""; }

  PROJECT_NAME="${PROJECT_NAME:-$(yq_get '.project_name')}"
  PROJECT_DIR="${PROJECT_DIR:-$(yq_get '.project_dir')}"
  PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-$(yq_get '.project_description')}"
  PROJECT_DESCRIPTION_LONG="${PROJECT_DESCRIPTION_LONG:-$(yq_get '.project_description_long')}"
  FRONTEND_FRAMEWORK="${FRONTEND_FRAMEWORK:-$(yq_get '.frontend_framework')}"
  FRONTEND_BUILD_CMD="${FRONTEND_BUILD_CMD:-$(yq_get '.frontend_build_cmd')}"
  FRONTEND_DEV_CMD="${FRONTEND_DEV_CMD:-$(yq_get '.frontend_dev_cmd')}"
  FRONTEND_TYPECHECK_CMD="${FRONTEND_TYPECHECK_CMD:-$(yq_get '.frontend_typecheck_cmd')}"
  BACKEND_FRAMEWORK="${BACKEND_FRAMEWORK:-$(yq_get '.backend_framework')}"
  BACKEND_BUILD_CMD="${BACKEND_BUILD_CMD:-$(yq_get '.backend_build_cmd')}"
  BACKEND_DEV_CMD="${BACKEND_DEV_CMD:-$(yq_get '.backend_dev_cmd')}"
  DATABASE="${DATABASE:-$(yq_get '.database')}"
  AUTH_METHOD="${AUTH_METHOD:-$(yq_get '.auth_method')}"
  INFRA="${INFRA:-$(yq_get '.infra')}"
  AI_SERVICES="${AI_SERVICES:-$(yq_get '.ai_services')}"
  DEPLOY_BACKEND_CMD="${DEPLOY_BACKEND_CMD:-$(yq_get '.deploy_backend_cmd')}"
  DEPLOY_FRONTEND_CMD="${DEPLOY_FRONTEND_CMD:-$(yq_get '.deploy_frontend_cmd')}"
  MAX_FILE_LINES="${MAX_FILE_LINES:-$(yq_get '.max_file_lines')}"
  BANNED_IMPORTS="${BANNED_IMPORTS:-$(yq_get '.banned_imports')}"

  # Multi-line values: never-do rules
  local fe_nd
  fe_nd="$(yq -r '.frontend_never_do[]? // empty' "$cfg" 2>/dev/null | sed 's/^/- /' || echo "")"
  FRONTEND_NEVER_DO="${FRONTEND_NEVER_DO:-$fe_nd}"

  local be_nd
  be_nd="$(yq -r '.backend_never_do[]? // empty' "$cfg" 2>/dev/null | sed 's/^/- /' || echo "")"
  BACKEND_NEVER_DO="${BACKEND_NEVER_DO:-$be_nd}"
}

# ---------------------------------------------------------------------------
# Validate required values
# ---------------------------------------------------------------------------
validate() {
  local errors=0

  if [[ -z "$PROJECT_NAME" ]]; then
    error "PROJECT_NAME is required (--project-name or project_name in config)"
    errors=$((errors + 1))
  fi

  if [[ -z "$PROJECT_DIR" ]]; then
    error "PROJECT_DIR is required (--project-dir or project_dir in config)"
    errors=$((errors + 1))
  elif [[ ! -d "$PROJECT_DIR" ]]; then
    error "PROJECT_DIR does not exist: $PROJECT_DIR"
    errors=$((errors + 1))
  fi

  if [[ $errors -gt 0 ]]; then
    fatal "$errors validation error(s). Use --help for usage."
  fi

  # Apply defaults for optional values
  PROJECT_DESCRIPTION="${PROJECT_DESCRIPTION:-$PROJECT_NAME project}"
  PROJECT_DESCRIPTION_LONG="${PROJECT_DESCRIPTION_LONG:-$PROJECT_DESCRIPTION}"
  FRONTEND_FRAMEWORK="${FRONTEND_FRAMEWORK:-Not specified}"
  FRONTEND_BUILD_CMD="${FRONTEND_BUILD_CMD:-echo 'No frontend build command configured'}"
  FRONTEND_DEV_CMD="${FRONTEND_DEV_CMD:-echo 'No frontend dev command configured'}"
  FRONTEND_TYPECHECK_CMD="${FRONTEND_TYPECHECK_CMD:-echo 'No typecheck command configured'}"
  BACKEND_FRAMEWORK="${BACKEND_FRAMEWORK:-Not specified}"
  BACKEND_BUILD_CMD="${BACKEND_BUILD_CMD:-echo 'No backend build command configured'}"
  BACKEND_DEV_CMD="${BACKEND_DEV_CMD:-echo 'No backend dev command configured'}"
  DATABASE="${DATABASE:-Not specified}"
  AUTH_METHOD="${AUTH_METHOD:-Not specified}"
  INFRA="${INFRA:-Not specified}"
  AI_SERVICES="${AI_SERVICES:-Not specified}"
  DEPLOY_BACKEND_CMD="${DEPLOY_BACKEND_CMD:-echo 'No backend deploy command configured'}"
  DEPLOY_FRONTEND_CMD="${DEPLOY_FRONTEND_CMD:-echo 'No frontend deploy command configured'}"
  FRONTEND_NEVER_DO="${FRONTEND_NEVER_DO:-'- (No frontend rules configured yet)'}"
  BACKEND_NEVER_DO="${BACKEND_NEVER_DO:-'- (No backend rules configured yet)'}"
  MAX_FILE_LINES="${MAX_FILE_LINES:-500}"
  BANNED_IMPORTS="${BANNED_IMPORTS:-}"
}

# ---------------------------------------------------------------------------
# Replace placeholders in a file
# ---------------------------------------------------------------------------
replace_placeholders() {
  local file="$1"

  # Use | as sed delimiter to avoid conflicts with paths
  sed -i \
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
    -e "s|{{PROJECT_DIR}}|${PROJECT_DIR}|g" \
    -e "s|{{PROJECT_DESCRIPTION_LONG}}|${PROJECT_DESCRIPTION_LONG}|g" \
    -e "s|{{PROJECT_DESCRIPTION}}|${PROJECT_DESCRIPTION}|g" \
    -e "s|{{FRONTEND_FRAMEWORK}}|${FRONTEND_FRAMEWORK}|g" \
    -e "s|{{FRONTEND_BUILD_CMD}}|${FRONTEND_BUILD_CMD}|g" \
    -e "s|{{FRONTEND_DEV_CMD}}|${FRONTEND_DEV_CMD}|g" \
    -e "s|{{FRONTEND_TYPECHECK_CMD}}|${FRONTEND_TYPECHECK_CMD}|g" \
    -e "s|{{BACKEND_FRAMEWORK}}|${BACKEND_FRAMEWORK}|g" \
    -e "s|{{BACKEND_BUILD_CMD}}|${BACKEND_BUILD_CMD}|g" \
    -e "s|{{BACKEND_DEV_CMD}}|${BACKEND_DEV_CMD}|g" \
    -e "s|{{DATABASE}}|${DATABASE}|g" \
    -e "s|{{AUTH_METHOD}}|${AUTH_METHOD}|g" \
    -e "s|{{INFRA}}|${INFRA}|g" \
    -e "s|{{AI_SERVICES}}|${AI_SERVICES}|g" \
    -e "s|{{DEPLOY_BACKEND_CMD}}|${DEPLOY_BACKEND_CMD}|g" \
    -e "s|{{DEPLOY_FRONTEND_CMD}}|${DEPLOY_FRONTEND_CMD}|g" \
    -e "s|{{MAX_FILE_LINES}}|${MAX_FILE_LINES}|g" \
    -e "s|{{BANNED_IMPORTS}}|${BANNED_IMPORTS}|g" \
    "$file"

  # Multi-line replacements need a different approach: use a temp file
  if [[ -n "$FRONTEND_NEVER_DO" ]]; then
    local escaped_fe
    escaped_fe="$(echo "$FRONTEND_NEVER_DO" | sed ':a;N;$!ba;s/\n/\\n/g')"
    sed -i "s|{{FRONTEND_NEVER_DO}}|${escaped_fe}|g" "$file"
  fi

  if [[ -n "$BACKEND_NEVER_DO" ]]; then
    local escaped_be
    escaped_be="$(echo "$BACKEND_NEVER_DO" | sed ':a;N;$!ba;s/\n/\\n/g')"
    sed -i "s|{{BACKEND_NEVER_DO}}|${escaped_be}|g" "$file"
  fi
}

# ---------------------------------------------------------------------------
# Copy hooks
# ---------------------------------------------------------------------------
copy_hooks() {
  local src="$SCRIPT_DIR/hooks"
  local dst="$PROJECT_DIR/.claude/hooks"

  if [[ ! -d "$src" ]]; then
    warn "No hooks/ directory found in template at $src -- skipping hook copy"
    return 0
  fi

  info "Copying hooks to $dst"
  mkdir -p "$dst/hard" "$dst/agent" "$dst/soft"

  for tier in hard agent soft; do
    if [[ -d "$src/$tier" ]]; then
      cp -v "$src/$tier/"*.sh "$dst/$tier/" 2>/dev/null || true
      chmod +x "$dst/$tier/"*.sh 2>/dev/null || true
    fi
  done

  ok "Hooks installed"
}

# ---------------------------------------------------------------------------
# Copy skills
# ---------------------------------------------------------------------------
copy_skills() {
  local src="$SCRIPT_DIR/skills"
  local dst="$PROJECT_DIR/.claude/skills"

  if [[ ! -d "$src" ]]; then
    warn "No skills/ directory found in template at $src -- skipping skill copy"
    return 0
  fi

  info "Copying skills to $dst"
  mkdir -p "$dst"

  # Copy all files and directories from skills/
  cp -rv "$src/"* "$dst/" 2>/dev/null || true

  ok "Skills installed"
}

# ---------------------------------------------------------------------------
# Generate settings.json
# ---------------------------------------------------------------------------
generate_settings() {
  local dst="$PROJECT_DIR/.claude/settings.json"
  local template="$SCRIPT_DIR/settings.template.json"

  if [[ ! -f "$template" ]]; then
    fatal "Template not found: $template"
  fi

  info "Generating settings.json"
  mkdir -p "$PROJECT_DIR/.claude"

  if [[ -f "$dst" ]]; then
    local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
    warn "Existing settings.json found -- backing up to $backup"
    cp "$dst" "$backup"
  fi

  # Copy template and strip _comment fields (they are not valid in Claude settings)
  # Keep them as-is since Claude Code ignores unknown keys, and they help humans
  cp "$template" "$dst"
  replace_placeholders "$dst"

  ok "settings.json generated at $dst"
}

# ---------------------------------------------------------------------------
# Generate CLAUDE.md
# ---------------------------------------------------------------------------
generate_claude_md() {
  local dst="$PROJECT_DIR/CLAUDE.md"
  local template="$SCRIPT_DIR/CLAUDE.template.md"

  if [[ ! -f "$template" ]]; then
    fatal "Template not found: $template"
  fi

  info "Generating CLAUDE.md"

  if [[ -f "$dst" ]]; then
    local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
    warn "Existing CLAUDE.md found -- backing up to $backup"
    cp "$dst" "$backup"
  fi

  cp "$template" "$dst"
  replace_placeholders "$dst"

  ok "CLAUDE.md generated at $dst"
}

# ---------------------------------------------------------------------------
# Validate the installation
# ---------------------------------------------------------------------------
validate_installation() {
  info "Validating installation..."
  local errors=0

  # Check settings.json exists and has no remaining placeholders
  local settings="$PROJECT_DIR/.claude/settings.json"
  if [[ ! -f "$settings" ]]; then
    error "Missing: $settings"
    errors=$((errors + 1))
  elif grep -q '{{' "$settings"; then
    warn "Unreplaced placeholders found in settings.json:"
    grep -o '{{[^}]*}}' "$settings" | sort -u | while read -r p; do
      warn "  $p"
    done
    errors=$((errors + 1))
  fi

  # Check CLAUDE.md exists
  if [[ ! -f "$PROJECT_DIR/CLAUDE.md" ]]; then
    error "Missing: $PROJECT_DIR/CLAUDE.md"
    errors=$((errors + 1))
  elif grep -q '{{' "$PROJECT_DIR/CLAUDE.md"; then
    warn "Unreplaced placeholders found in CLAUDE.md:"
    grep -o '{{[^}]*}}' "$PROJECT_DIR/CLAUDE.md" | sort -u | while read -r p; do
      warn "  $p"
    done
    errors=$((errors + 1))
  fi

  # Check hook directories exist
  for tier in hard agent soft; do
    local dir="$PROJECT_DIR/.claude/hooks/$tier"
    if [[ ! -d "$dir" ]]; then
      warn "Hook directory missing: $dir"
    else
      local count
      count=$(find "$dir" -name '*.sh' -type f 2>/dev/null | wc -l)
      info "  $tier hooks: $count scripts"
    fi
  done

  # Check skills directory
  if [[ -d "$PROJECT_DIR/.claude/skills" ]]; then
    local skill_count
    skill_count=$(find "$PROJECT_DIR/.claude/skills" -name '*.md' -type f 2>/dev/null | wc -l)
    info "  Skills: $skill_count pattern files"
  fi

  if [[ $errors -eq 0 ]]; then
    echo ""
    ok "=========================================="
    ok "  LoopyEra installation complete!"
    ok "=========================================="
    echo ""
    info "Project:    $PROJECT_NAME"
    info "Location:   $PROJECT_DIR"
    info "Settings:   $PROJECT_DIR/.claude/settings.json"
    info "Hooks:      $PROJECT_DIR/.claude/hooks/"
    info "Skills:     $PROJECT_DIR/.claude/skills/"
    info "CLAUDE.md:  $PROJECT_DIR/CLAUDE.md"
    echo ""
    info "Next steps:"
    info "  1. Review the generated CLAUDE.md and customize as needed"
    info "  2. Edit .claude/skills/never-do.md with your project's forbidden patterns"
    info "  3. Edit .claude/skills/frontend-patterns.md with your coding standards"
    info "  4. Edit .claude/skills/backend-patterns.md with your coding standards"
    info "  5. Run 'claude' in your project directory to start a session"
    echo ""
  else
    echo ""
    warn "Installation completed with $errors warning(s). Review the issues above."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  echo "  LoopyEra Setup"
  echo "  Autonomous Self-Improving Architecture for Claude Code"
  echo ""

  parse_args "$@"

  # Load YAML config if specified
  if [[ -n "$CONFIG_FILE" ]]; then
    load_yaml_config "$CONFIG_FILE"
  fi

  # Validate required values
  validate

  info "Project: $PROJECT_NAME"
  info "Target:  $PROJECT_DIR"
  echo ""

  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY RUN] Would install to: $PROJECT_DIR/.claude/"
    info "[DRY RUN] Would generate: $PROJECT_DIR/CLAUDE.md"
    info "[DRY RUN] Would generate: $PROJECT_DIR/.claude/settings.json"
    info "[DRY RUN] Would copy hooks from: $SCRIPT_DIR/hooks/"
    info "[DRY RUN] Would copy skills from: $SCRIPT_DIR/skills/"
    exit 0
  fi

  # Create target directories
  mkdir -p "$PROJECT_DIR/.claude/hooks"
  mkdir -p "$PROJECT_DIR/.claude/skills"

  # Install components
  copy_hooks
  copy_skills
  generate_settings
  generate_claude_md

  # Validate
  validate_installation
}

main "$@"

#!/usr/bin/env bash
# preflight-check.sh — Pre-flight sanity check for ASK framework
# Usage: ./scripts/preflight-check.sh
#
# Verifies that the ASK framework is intact and ready to start a build.
# Run this BEFORE starting an agent build to catch environment issues early.

set -euo pipefail

# --- Config ---
ASK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
WARN=0
RESULTS=()

# --- Colors (if terminal supports them) ---
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[0;33m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  GREEN=''
  RED=''
  YELLOW=''
  BOLD=''
  RESET=''
fi

# --- Functions ---

check() {
  local name="$1"
  local status="$2"
  local notes="$3"

  case "$status" in
    PASS)
      PASS=$((PASS + 1))
      printf "  ${GREEN}[PASS]${RESET} %s — %s\n" "$name" "$notes"
      ;;
    FAIL)
      FAIL=$((FAIL + 1))
      printf "  ${RED}[FAIL]${RESET} %s — %s\n" "$name" "$notes"
      ;;
    WARN)
      WARN=$((WARN + 1))
      printf "  ${YELLOW}[WARN]${RESET} %s — %s\n" "$name" "$notes"
      ;;
  esac

  RESULTS+=("$name|$status|$notes")
}

check_dir() {
  local path="$1"
  local label="$2"
  if [[ -d "$ASK_DIR/$path" ]]; then
    local count
    count=$(find "$ASK_DIR/$path" -maxdepth 1 -type f | wc -l | tr -d ' ')
    check "$label" "PASS" "$path/ ($count files)"
  else
    check "$label" "FAIL" "$path/ not found"
  fi
}

check_file() {
  local path="$1"
  local label="$2"
  if [[ -f "$ASK_DIR/$path" ]]; then
    check "$label" "PASS" "$path exists"
  else
    check "$label" "FAIL" "$path not found"
  fi
}

check_tool() {
  local tool="$1"
  local required="$2"  # "required" or "optional"
  if command -v "$tool" &>/dev/null; then
    local version
    version=$("$tool" --version 2>&1 | head -1 || echo "version unknown")
    check "$tool" "PASS" "$version"
  else
    if [[ "$required" == "required" ]]; then
      check "$tool" "FAIL" "Not found — required for ASK builds"
    else
      check "$tool" "WARN" "Not found — some features may be unavailable"
    fi
  fi
}

# --- Header ---

echo ""
printf "${BOLD}ASK Pre-Flight Check${RESET}\n"
echo "================================="
echo "ASK directory: $ASK_DIR"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# --- 1. Directory Structure ---

printf "${BOLD}1. Directory Structure${RESET}\n"
check_dir "commands" "Commands directory"
check_dir "templates" "Templates directory"
check_dir "templates/openclaw" "OpenClaw templates"
check_dir "templates/hermes" "Hermes templates"
check_dir "templates/claude-code" "Claude Code templates"
check_dir "templates/common" "Common templates"
check_dir "references" "References directory"
check_dir "scripts" "Scripts directory"
echo ""

# --- 2. Core Files ---

printf "${BOLD}2. Core Files${RESET}\n"
check_file "CLAUDE.md" "CLAUDE.md"
check_file "README.md" "README.md"
echo ""

# --- 3. Commands ---

printf "${BOLD}3. Commands${RESET}\n"
required_commands=(
  "ask-new.md"
  "ask-discovery.md"
  "ask-research.md"
  "ask-architecture.md"
  "ask-build.md"
  "ask-validate.md"
  "ask-iterate.md"
  "ask-progress.md"
  "ask-skip.md"
  "ask-resume.md"
  "ask-export.md"
)
for cmd in "${required_commands[@]}"; do
  check_file "commands/$cmd" "Command: $cmd"
done

# Check for crew command (optional but recommended)
if [[ -f "$ASK_DIR/commands/ask-crew.md" ]]; then
  check "Command: ask-crew.md" "PASS" "Multi-agent crew support available"
else
  check "Command: ask-crew.md" "WARN" "Multi-agent crew command not found"
fi
echo ""

# --- 4. Templates ---

printf "${BOLD}4. Templates${RESET}\n"

# OpenClaw templates
openclaw_templates=("SOUL.md.tmpl" "IDENTITY.md.tmpl" "USER.md.tmpl" "MEMORY.md.tmpl" "TOOLS.md.tmpl" "AGENTS.md.tmpl" "HEARTBEAT.md.tmpl")
for tmpl in "${openclaw_templates[@]}"; do
  if [[ -f "$ASK_DIR/templates/openclaw/$tmpl" ]]; then
    check "OpenClaw: $tmpl" "PASS" "Template exists"
  else
    check "OpenClaw: $tmpl" "WARN" "Template missing — OpenClaw builds may be incomplete"
  fi
done

# Claude Code templates
cc_templates=("CLAUDE.md.tmpl" "settings.json.tmpl")
for tmpl in "${cc_templates[@]}"; do
  if [[ -f "$ASK_DIR/templates/claude-code/$tmpl" ]]; then
    check "Claude Code: $tmpl" "PASS" "Template exists"
  else
    check "Claude Code: $tmpl" "WARN" "Template missing"
  fi
done

# Hermes templates
if [[ -f "$ASK_DIR/templates/hermes/agent-file.tmpl" ]]; then
  check "Hermes: agent-file.tmpl" "PASS" "Template exists"
else
  check "Hermes: agent-file.tmpl" "WARN" "Template missing"
fi

# Common templates
common_templates=("guardrails.md.tmpl" "system-prompt.md.tmpl" "org-profile.md.tmpl")
for tmpl in "${common_templates[@]}"; do
  if [[ -f "$ASK_DIR/templates/common/$tmpl" ]]; then
    check "Common: $tmpl" "PASS" "Template exists"
  else
    check "Common: $tmpl" "WARN" "Template missing"
  fi
done
echo ""

# --- 5. References ---

printf "${BOLD}5. Reference Library${RESET}\n"
ref_count=$(find "$ASK_DIR/references" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$ref_count" -ge 9 ]]; then
  check "Reference count" "PASS" "$ref_count reference documents"
elif [[ "$ref_count" -ge 5 ]]; then
  check "Reference count" "WARN" "Only $ref_count references — research phase may lack coverage"
else
  check "Reference count" "FAIL" "Only $ref_count references — research phase will be impaired"
fi

# Check key references
key_refs=("anthropic-agent-guide.md" "prompt-engineering.md" "mcp-patterns.md" "evaluation-frameworks.md" "deployment-patterns.md")
for ref in "${key_refs[@]}"; do
  if [[ -f "$ASK_DIR/references/$ref" ]]; then
    check "Reference: $ref" "PASS" "Available"
  else
    check "Reference: $ref" "WARN" "Missing — may affect research quality"
  fi
done
echo ""

# --- 6. Scripts ---

printf "${BOLD}6. Scripts${RESET}\n"
scripts=("validate-agent.sh" "skill-audit.sh" "preflight-check.sh")
for script in "${scripts[@]}"; do
  if [[ -f "$ASK_DIR/scripts/$script" ]]; then
    if [[ -x "$ASK_DIR/scripts/$script" ]]; then
      check "Script: $script" "PASS" "Exists and executable"
    else
      check "Script: $script" "WARN" "Exists but not executable — run: chmod +x scripts/$script"
    fi
  else
    if [[ "$script" == "preflight-check.sh" ]]; then
      check "Script: $script" "PASS" "Running now"
    else
      check "Script: $script" "WARN" "Not found"
    fi
  fi
done
echo ""

# --- 7. Required Tools ---

printf "${BOLD}7. Required Tools${RESET}\n"
check_tool "python3" "required"
check_tool "node" "required"
check_tool "git" "required"
echo ""

# --- 8. Optional Tools ---

printf "${BOLD}8. Optional Tools (runtime-specific)${RESET}\n"
check_tool "hermes" "optional"
check_tool "openclaw" "optional"
check_tool "claude" "optional"
check_tool "docker" "optional"
echo ""

# --- 9. State Directory ---

printf "${BOLD}9. Build State${RESET}\n"
if [[ -d "$ASK_DIR/ask-state" ]]; then
  if [[ -f "$ASK_DIR/ask-state/state.json" ]]; then
    # Check if there is an active build
    if python3 -c "
import json
with open('$ASK_DIR/ask-state/state.json') as f:
    state = json.load(f)
agent = state.get('agent_name', 'unknown')
phase = state.get('current_phase', 'unknown')
print(f'{agent} (phase: {phase})')
" 2>/dev/null; then
      active_build=$(python3 -c "
import json
with open('$ASK_DIR/ask-state/state.json') as f:
    state = json.load(f)
print(f\"{state.get('agent_name', 'unknown')} (phase: {state.get('current_phase', 'unknown')})\")
" 2>/dev/null || echo "could not parse")
      check "Active build" "WARN" "Existing build detected: $active_build"
    else
      check "Active build" "WARN" "state.json exists but could not parse"
    fi
  else
    check "Build state" "PASS" "No active build — ready for new agent"
  fi
else
  check "Build state" "PASS" "No ask-state/ — ready for new agent"
fi
echo ""

# --- Summary ---

echo "================================="
printf "${BOLD}Summary${RESET}\n"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "  WARN: $WARN"
echo "  Total: $((PASS + FAIL + WARN))"
echo ""

if [[ "$FAIL" -eq 0 ]]; then
  printf "${GREEN}${BOLD}READY${RESET} — ASK framework is ready for agent builds.\n"
  if [[ "$WARN" -gt 0 ]]; then
    echo "($WARN warnings — review recommended but not blocking)"
  fi
else
  printf "${RED}${BOLD}NOT READY${RESET} — $FAIL critical issue(s) must be resolved before building.\n"
  echo ""
  echo "Failed checks:"
  for result in "${RESULTS[@]}"; do
    IFS='|' read -r name status notes <<< "$result"
    if [[ "$status" == "FAIL" ]]; then
      echo "  - $name: $notes"
    fi
  done
fi

echo ""

# Exit code: 0 if no failures, 1 if any failures
[[ "$FAIL" -eq 0 ]]

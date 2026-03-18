#!/usr/bin/env bash
# ASK — Agent Setup Kit — Installer
# Usage: curl -sL https://raw.githubusercontent.com/jcmazz/ASK/main/install.sh | bash
#    or: git clone https://github.com/jcmazz/ASK.git && cd ASK && ./install.sh
#
# Installs ASK to ~/.claude/ask/ and registers commands in ~/.claude/commands/ask/

set -euo pipefail

# --- Config ---
ASK_REPO="https://github.com/jcmazz/ASK.git"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
ASK_DIR="$CLAUDE_DIR/ask"
COMMANDS_DIR="$CLAUDE_DIR/commands/ask"
VERSION="0.1.0"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Functions ---
info()  { echo -e "${BLUE}▸${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}!${NC} $1"; }
fail()  { echo -e "${RED}✗${NC} $1"; exit 1; }

# --- Banner ---
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE} ASK — Agent Setup Kit — Installer v${VERSION}${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# --- Pre-checks ---
if [[ ! -d "$CLAUDE_DIR" ]]; then
  fail "Claude Code config directory not found at $CLAUDE_DIR. Is Claude Code installed?"
fi

# --- Check for existing installation ---
if [[ -d "$ASK_DIR" ]]; then
  warn "ASK already installed at $ASK_DIR"
  echo -n "  Reinstall? [y/N] "
  read -r answer
  if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
  info "Removing existing installation..."
  rm -rf "$ASK_DIR"
  rm -rf "$COMMANDS_DIR"
fi

# --- Install framework ---
info "Installing ASK framework to $ASK_DIR..."

# Detect if running from within the repo
if [[ -f "./CLAUDE.md" && -d "./commands" && -d "./templates" ]]; then
  info "Installing from local repo..."
  mkdir -p "$ASK_DIR"
  cp -R commands/ "$ASK_DIR/commands/"
  cp -R templates/ "$ASK_DIR/templates/"
  cp -R references/ "$ASK_DIR/references/"
  cp -R scripts/ "$ASK_DIR/scripts/"
  cp CLAUDE.md "$ASK_DIR/"
  cp README.md "$ASK_DIR/"
  [[ -d "ask-state" ]] && mkdir -p "$ASK_DIR/ask-state"
else
  info "Cloning from $ASK_REPO..."
  git clone --depth 1 "$ASK_REPO" "$ASK_DIR" 2>/dev/null || fail "Failed to clone repo. Check your network and access."
fi

# Write VERSION
echo "$VERSION" > "$ASK_DIR/VERSION"
ok "Framework installed to $ASK_DIR"

# --- Make scripts executable ---
chmod +x "$ASK_DIR/scripts/"*.sh 2>/dev/null || true
ok "Scripts made executable"

# --- Register commands ---
info "Registering commands in $COMMANDS_DIR..."
mkdir -p "$COMMANDS_DIR"

# Command definitions: name|description|argument-hint|source-file
COMMANDS=(
  "new|Start a new agent build|<agent-name>|ask-new.md"
  "discovery|Run or resume the adaptive discovery interview||ask-discovery.md"
  "research|Deep research on domain, skills, architecture|[area]|ask-research.md"
  "architecture|Design the complete agent system||ask-architecture.md"
  "build|Generate all agent files||ask-build.md"
  "validate|Test the agent (checklist + simulation + eval)|[level]|ask-validate.md"
  "iterate|Adjust agent based on feedback||ask-iterate.md"
  "progress|Show current build status||ask-progress.md"
  "skip|Skip current phase (with quality warning)||ask-skip.md"
  "resume|Resume from where you left off||ask-resume.md"
  "export|Export agent files to a target directory|<path>|ask-export.md"
  "crew|Build a coordinated multi-agent crew|<name> <n>|ask-crew.md"
)

for cmd_def in "${COMMANDS[@]}"; do
  IFS='|' read -r cmd_name cmd_desc cmd_args cmd_file <<< "$cmd_def"

  cat > "$COMMANDS_DIR/${cmd_name}.md" << CMDEOF
---
name: ask:${cmd_name}
description: ${cmd_desc}
argument-hint: "${cmd_args}"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
  - WebSearch
  - WebFetch
---

<objective>
${cmd_desc}
</objective>

<execution_context>
@${ASK_DIR}/commands/${cmd_file}
@${ASK_DIR}/CLAUDE.md
</execution_context>

<context>
\$ARGUMENTS: ${cmd_args:-"None"}

ASK state directory: \`ask-state/\` in the current working directory.
Always read \`ask-state/state.json\` before any operation.
</context>

<process>
Execute the command from @${ASK_DIR}/commands/${cmd_file} end-to-end.
Follow all instructions, gates, and state management rules defined in the command file.
Templates are at ${ASK_DIR}/templates/
References are at ${ASK_DIR}/references/
Scripts are at ${ASK_DIR}/scripts/
</process>
CMDEOF

done

ok "Registered ${#COMMANDS[@]} commands"

# --- Generate file manifest ---
info "Generating file manifest..."
MANIFEST_FILE="$ASK_DIR/ask-file-manifest.json"

echo "{" > "$MANIFEST_FILE"
echo "  \"version\": \"$VERSION\"," >> "$MANIFEST_FILE"
echo "  \"installed\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$MANIFEST_FILE"
echo "  \"files\": {" >> "$MANIFEST_FILE"

first=true
while IFS= read -r -d '' file; do
  rel_path="${file#$ASK_DIR/}"
  hash=$(shasum -a 256 "$file" | cut -d' ' -f1)
  if [[ "$first" == true ]]; then
    first=false
  else
    echo "," >> "$MANIFEST_FILE"
  fi
  printf "    \"%s\": \"%s\"" "$rel_path" "$hash" >> "$MANIFEST_FILE"
done < <(find "$ASK_DIR" -type f -not -path "*/.git/*" -not -name "ask-file-manifest.json" -print0 | sort -z)

echo "" >> "$MANIFEST_FILE"
echo "  }" >> "$MANIFEST_FILE"
echo "}" >> "$MANIFEST_FILE"

ok "File manifest generated"

# --- Summary ---
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} ASK installed successfully!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Framework:  $ASK_DIR"
echo "  Commands:   $COMMANDS_DIR (${#COMMANDS[@]} commands)"
echo "  Version:    $VERSION"
echo ""
echo "  Usage:"
echo "    /ask:new my-agent        Start building an agent"
echo "    /ask:crew my-crew 3      Build a 3-agent crew"
echo "    /ask:progress            Check build status"
echo ""
echo "  Run the preflight check:"
echo "    $ASK_DIR/scripts/preflight-check.sh"
echo ""

#!/usr/bin/env bash
# validate-agent.sh — Technical checklist validation for ASK-built agents
# Usage: ./scripts/validate-agent.sh <agent-dir> [--runtime openclaw|hermes|claude-code] [--format json|report]
#
# Runs Level 1 (Technical Checklist) validation against a built agent directory.
# Checks file existence, well-formedness, structural integrity, cross-file consistency,
# template residue, encoding, file size sanity, and internal link validity.
# Used by /ask:validate as the automated checklist step.

set -euo pipefail

# --- Config ---
AGENT_DIR=""
RUNTIME=""
FORMAT="report"
PASS=0
FAIL=0
WARN=0
RESULTS=()

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: validate-agent.sh <agent-dir> [--runtime openclaw|hermes|claude-code] [--format json|report]"
      echo ""
      echo "Runs technical checklist validation on a built agent."
      echo ""
      echo "Options:"
      echo "  --runtime   Agent runtime (auto-detected if omitted)"
      echo "  --format    Output: report (default) or json"
      echo ""
      echo "Checks performed:"
      echo "  - File existence and non-emptiness"
      echo "  - Format validation (JSON, YAML, Markdown)"
      echo "  - Cross-file consistency (tool references, guardrails)"
      echo "  - Template residue (unresolved {{VARIABLE}} patterns)"
      echo "  - File size sanity (stubs <50B, bloated >50KB)"
      echo "  - UTF-8 encoding verification"
      echo "  - Internal link/reference validation"
      echo "  - Memory directory structure"
      echo "  - Guardrail presence"
      exit 0
      ;;
    *)
      if [[ -z "$AGENT_DIR" ]]; then
        AGENT_DIR="$1"
      else
        echo "Unknown arg: $1"; exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$AGENT_DIR" ]]; then
  echo "Error: Agent directory required."
  echo "Usage: validate-agent.sh <agent-dir> [--runtime openclaw|hermes|claude-code]"
  exit 1
fi

if [[ ! -d "$AGENT_DIR" ]]; then
  echo "Error: Directory not found: $AGENT_DIR"
  exit 1
fi

# --- Functions ---

check() {
  local name="$1"
  local status="$2"  # PASS, FAIL, WARN
  local notes="$3"

  case "$status" in
    PASS) PASS=$((PASS + 1)) ;;
    FAIL) FAIL=$((FAIL + 1)) ;;
    WARN) WARN=$((WARN + 1)) ;;
  esac

  RESULTS+=("$name|$status|$notes")
}

file_exists() {
  local path="$1"
  local label="$2"
  if [[ -f "$AGENT_DIR/$path" ]]; then
    local lines
    lines=$(wc -l < "$AGENT_DIR/$path" | tr -d ' ')
    if [[ "$lines" -eq 0 ]]; then
      check "$label exists" "WARN" "$path exists but is empty (0 lines)"
    else
      check "$label exists" "PASS" "$path ($lines lines)"
    fi
  else
    check "$label exists" "FAIL" "$path not found"
  fi
}

file_nonempty() {
  local path="$1"
  local label="$2"
  if [[ -f "$AGENT_DIR/$path" ]]; then
    local size
    size=$(wc -c < "$AGENT_DIR/$path" | tr -d ' ')
    if [[ "$size" -gt 10 ]]; then
      check "$label non-empty" "PASS" "$size bytes"
    else
      check "$label non-empty" "FAIL" "File exists but only $size bytes"
    fi
  else
    check "$label non-empty" "FAIL" "File not found"
  fi
}

valid_json() {
  local path="$1"
  local label="$2"
  if [[ -f "$AGENT_DIR/$path" ]]; then
    if python3 -c "import json; json.load(open('$AGENT_DIR/$path'))" 2>/dev/null; then
      check "$label valid JSON" "PASS" "Parsed successfully"
    else
      check "$label valid JSON" "FAIL" "JSON parse error"
    fi
  else
    check "$label valid JSON" "FAIL" "File not found"
  fi
}

valid_yaml() {
  local path="$1"
  local label="$2"
  if [[ -f "$AGENT_DIR/$path" ]]; then
    if python3 -c "import yaml; yaml.safe_load(open('$AGENT_DIR/$path'))" 2>/dev/null; then
      check "$label valid YAML" "PASS" "Parsed successfully"
    else
      check "$label valid YAML" "FAIL" "YAML parse error"
    fi
  else
    check "$label valid YAML" "FAIL" "File not found"
  fi
}

valid_markdown() {
  local path="$1"
  local label="$2"
  if [[ -f "$AGENT_DIR/$path" ]]; then
    # Check for basic markdown structure (has at least one heading)
    if grep -qE "^#" "$AGENT_DIR/$path" 2>/dev/null; then
      check "$label valid markdown" "PASS" "Has heading structure"
    else
      check "$label valid markdown" "WARN" "No markdown headings found"
    fi
  else
    check "$label valid markdown" "FAIL" "File not found"
  fi
}

dir_exists() {
  local path="$1"
  local label="$2"
  if [[ -d "$AGENT_DIR/$path" ]]; then
    local count
    count=$(find "$AGENT_DIR/$path" -type f | wc -l | tr -d ' ')
    check "$label directory" "PASS" "$path ($count files)"
  else
    check "$label directory" "FAIL" "$path not found"
  fi
}

# --- NEW: Template residue check ---
check_template_residue() {
  local residue_files=()
  local residue_count=0

  while IFS= read -r -d '' file; do
    local matches
    matches=$(grep -cE '\{\{[A-Z_]+\}\}' "$file" 2>/dev/null || true)
    if [[ "$matches" -gt 0 ]]; then
      residue_files+=("$(basename "$file"):$matches")
      residue_count=$((residue_count + matches))
    fi
  done < <(find "$AGENT_DIR" -maxdepth 2 -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) -print0 2>/dev/null)

  if [[ "$residue_count" -gt 0 ]]; then
    local detail=""
    for entry in "${residue_files[@]}"; do
      detail="${detail}${entry} "
    done
    check "Template residue" "FAIL" "$residue_count unresolved {{VARIABLE}} in: ${detail}"
  else
    check "Template residue" "PASS" "No unresolved template variables found"
  fi
}

# --- NEW: File size sanity check ---
check_file_sizes() {
  local stubs=()
  local bloated=()

  while IFS= read -r -d '' file; do
    local size
    size=$(wc -c < "$file" | tr -d ' ')
    local name
    name=$(basename "$file")

    if [[ "$size" -lt 50 ]]; then
      stubs+=("$name(${size}B)")
    elif [[ "$size" -gt 51200 ]]; then  # 50KB
      bloated+=("$name($((size/1024))KB)")
    fi
  done < <(find "$AGENT_DIR" -maxdepth 2 -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) -print0 2>/dev/null)

  if [[ "${#stubs[@]}" -gt 0 ]]; then
    check "File size (stubs)" "WARN" "Files under 50 bytes (likely stubs): ${stubs[*]}"
  else
    check "File size (stubs)" "PASS" "No stub files detected"
  fi

  if [[ "${#bloated[@]}" -gt 0 ]]; then
    check "File size (bloated)" "WARN" "Files over 50KB (possibly bloated): ${bloated[*]}"
  else
    check "File size (bloated)" "PASS" "No oversized files detected"
  fi
}

# --- NEW: UTF-8 encoding check ---
check_encoding() {
  local non_utf8=()

  while IFS= read -r -d '' file; do
    # Use file command to check encoding
    local encoding
    encoding=$(file --mime-encoding "$file" 2>/dev/null | awk -F': ' '{print $2}' | tr -d '[:space:]')

    # Accept utf-8, us-ascii (subset of utf-8), and empty files
    if [[ "$encoding" != "utf-8" && "$encoding" != "us-ascii" && "$encoding" != "binary" ]]; then
      non_utf8+=("$(basename "$file"):$encoding")
    fi
  done < <(find "$AGENT_DIR" -maxdepth 2 -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" -o -name "*.txt" \) -print0 2>/dev/null)

  if [[ "${#non_utf8[@]}" -gt 0 ]]; then
    check "UTF-8 encoding" "FAIL" "Non-UTF-8 files: ${non_utf8[*]}"
  else
    check "UTF-8 encoding" "PASS" "All text files are UTF-8 compatible"
  fi
}

# --- NEW: Internal link/reference check ---
check_internal_links() {
  local broken_refs=()

  while IFS= read -r -d '' file; do
    # Find references like "see TOOLS.md", "defined in MEMORY.md", "check config.yaml"
    while IFS= read -r ref; do
      # Extract the referenced filename
      local ref_file
      ref_file=$(echo "$ref" | grep -oE '[A-Z][A-Z0-9_-]*\.(md|yaml|yml|json)' | head -1)
      if [[ -n "$ref_file" && ! -f "$AGENT_DIR/$ref_file" ]]; then
        broken_refs+=("$(basename "$file")->$ref_file")
      fi
    done < <(grep -iE '(see|defined in|check|refer to|documented in|described in)\s+[A-Z][A-Z0-9_-]*\.(md|yaml|yml|json)' "$file" 2>/dev/null || true)
  done < <(find "$AGENT_DIR" -maxdepth 2 -type f -name "*.md" -print0 2>/dev/null)

  if [[ "${#broken_refs[@]}" -gt 0 ]]; then
    check "Internal references" "FAIL" "Broken refs: ${broken_refs[*]}"
  else
    check "Internal references" "PASS" "All internal file references resolve"
  fi
}

# --- NEW: Cross-file tool consistency check ---
check_tool_consistency() {
  # Only for OpenClaw: verify tools mentioned in SOUL.md exist in TOOLS.md
  if [[ "$RUNTIME" != "openclaw" ]]; then
    return
  fi

  if [[ ! -f "$AGENT_DIR/SOUL.md" || ! -f "$AGENT_DIR/TOOLS.md" ]]; then
    return
  fi

  local missing_tools=()

  # Extract tool-like references from SOUL.md (words after "use", "call", "invoke", "tool:")
  while IFS= read -r tool; do
    # Check if this tool name appears in TOOLS.md
    if ! grep -qi "$tool" "$AGENT_DIR/TOOLS.md" 2>/dev/null; then
      missing_tools+=("$tool")
    fi
  done < <(grep -oiE '(use|call|invoke|run|execute)\s+[a-z_]+' "$AGENT_DIR/SOUL.md" 2>/dev/null | awk '{print $2}' | sort -u || true)

  if [[ "${#missing_tools[@]}" -gt 0 ]]; then
    check "Tool consistency (SOUL<>TOOLS)" "WARN" "Tools in SOUL.md not found in TOOLS.md: ${missing_tools[*]}"
  else
    check "Tool consistency (SOUL<>TOOLS)" "PASS" "Tool references are consistent"
  fi
}

# --- NEW: Memory structure check ---
check_memory_structure() {
  local expected_dirs=("memory" "memory/vault" "memory/hot-context")
  local missing_dirs=()
  local has_memory=false

  for mem_dir in "${expected_dirs[@]}"; do
    if [[ -d "$AGENT_DIR/$mem_dir" ]]; then
      has_memory=true
    else
      missing_dirs+=("$mem_dir")
    fi
  done

  # Only check if memory is configured (at least one dir exists)
  if [[ "$has_memory" == true ]]; then
    if [[ "${#missing_dirs[@]}" -gt 0 ]]; then
      check "Memory structure" "WARN" "Missing memory dirs: ${missing_dirs[*]}"
    else
      check "Memory structure" "PASS" "All memory directories present"
    fi

    # Check if MEMORY.md references match actual directory structure
    if [[ -f "$AGENT_DIR/MEMORY.md" ]]; then
      for mem_dir in "vault" "hot-context" ".embeddings"; do
        if grep -qi "$mem_dir" "$AGENT_DIR/MEMORY.md" 2>/dev/null; then
          if [[ ! -d "$AGENT_DIR/memory/$mem_dir" ]]; then
            check "Memory dir: $mem_dir" "WARN" "Referenced in MEMORY.md but directory missing"
          fi
        fi
      done
    fi
  fi
}

# --- NEW: Guardrail coverage check ---
check_guardrail_coverage() {
  # Check that guardrails from architecture are reflected in generated files
  local guardrail_keywords=("never" "must not" "prohibited" "forbidden" "always" "required" "escalate")
  local guardrail_count=0
  local checked_files=()

  case "$RUNTIME" in
    openclaw)
      checked_files=("SOUL.md" "IDENTITY.md")
      ;;
    claude-code)
      checked_files=("CLAUDE.md")
      ;;
    hermes)
      checked_files=("SOUL.md" "system-prompt.md" "AGENTS.md")
      ;;
  esac

  for cf in "${checked_files[@]}"; do
    if [[ -f "$AGENT_DIR/$cf" ]]; then
      for keyword in "${guardrail_keywords[@]}"; do
        local count
        count=$(grep -ci "$keyword" "$AGENT_DIR/$cf" 2>/dev/null || echo "0")
        guardrail_count=$((guardrail_count + count))
      done
    fi
  done

  if [[ "$guardrail_count" -ge 5 ]]; then
    check "Guardrail coverage" "PASS" "$guardrail_count guardrail statements found"
  elif [[ "$guardrail_count" -ge 1 ]]; then
    check "Guardrail coverage" "WARN" "Only $guardrail_count guardrail statements — may be insufficient"
  else
    check "Guardrail coverage" "FAIL" "No guardrail statements found in agent files"
  fi
}

# --- Auto-detect runtime ---

detect_runtime() {
  if [[ -f "$AGENT_DIR/SOUL.md" && -f "$AGENT_DIR/IDENTITY.md" ]]; then
    echo "openclaw"
  elif [[ -f "$AGENT_DIR/CLAUDE.md" && -d "$AGENT_DIR/.claude" ]]; then
    echo "claude-code"
  elif [[ -f "$AGENT_DIR/agent.json" || -f "$AGENT_DIR/system-prompt.md" ]]; then
    echo "hermes"
  else
    echo "unknown"
  fi
}

if [[ -z "$RUNTIME" ]]; then
  RUNTIME=$(detect_runtime)
fi

# --- Run checks ---

echo "# Agent Validation — Technical Checklist"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Agent: $AGENT_DIR"
echo "Runtime: $RUNTIME"
echo ""

# Runtime-specific file checks
case "$RUNTIME" in
  openclaw)
    file_exists "SOUL.md" "SOUL.md"
    file_nonempty "SOUL.md" "SOUL.md"
    valid_markdown "SOUL.md" "SOUL.md"

    file_exists "IDENTITY.md" "IDENTITY.md"
    file_nonempty "IDENTITY.md" "IDENTITY.md"

    file_exists "USER.md" "USER.md"
    file_nonempty "USER.md" "USER.md"

    file_exists "MEMORY.md" "MEMORY.md"
    file_nonempty "MEMORY.md" "MEMORY.md"

    file_exists "TOOLS.md" "TOOLS.md"
    file_nonempty "TOOLS.md" "TOOLS.md"

    file_exists "AGENTS.md" "AGENTS.md"
    file_nonempty "AGENTS.md" "AGENTS.md"

    # Optional files
    if [[ -f "$AGENT_DIR/HEARTBEAT.md" ]]; then
      file_nonempty "HEARTBEAT.md" "HEARTBEAT.md"
    fi

    if [[ -f "$AGENT_DIR/config.yaml" ]]; then
      valid_yaml "config.yaml" "config.yaml"
    fi

    # Check guardrails are present in SOUL.md
    if [[ -f "$AGENT_DIR/SOUL.md" ]]; then
      if grep -qiE "(guardrail|never|must not|prohibited|forbidden)" "$AGENT_DIR/SOUL.md" 2>/dev/null; then
        check "Guardrails in SOUL.md" "PASS" "Guardrail rules found"
      else
        check "Guardrails in SOUL.md" "WARN" "No guardrail keywords detected"
      fi
    fi

    # Check system prompt exists somewhere
    if grep -qiE "(system prompt|you are|your role)" "$AGENT_DIR/SOUL.md" 2>/dev/null || \
       grep -qiE "(system prompt|you are|your role)" "$AGENT_DIR/AGENTS.md" 2>/dev/null; then
      check "System prompt present" "PASS" "Found in SOUL.md or AGENTS.md"
    else
      check "System prompt present" "WARN" "No clear system prompt found"
    fi
    ;;

  claude-code)
    file_exists "CLAUDE.md" "CLAUDE.md"
    file_nonempty "CLAUDE.md" "CLAUDE.md"
    valid_markdown "CLAUDE.md" "CLAUDE.md"

    dir_exists ".claude" ".claude config"

    if [[ -f "$AGENT_DIR/.claude/settings.json" ]]; then
      valid_json ".claude/settings.json" "settings.json"
    fi

    # Check for commands
    if [[ -d "$AGENT_DIR/.claude/commands" ]]; then
      cmd_count=$(find "$AGENT_DIR/.claude/commands" -name "*.md" -type f | wc -l | tr -d ' ')
      check "Custom commands" "PASS" "$cmd_count command files"
    else
      check "Custom commands" "WARN" "No commands/ directory"
    fi

    # Check guardrails in CLAUDE.md
    if grep -qiE "(guardrail|never|must not|prohibited|forbidden)" "$AGENT_DIR/CLAUDE.md" 2>/dev/null; then
      check "Guardrails in CLAUDE.md" "PASS" "Guardrail rules found"
    else
      check "Guardrails in CLAUDE.md" "WARN" "No guardrail keywords detected"
    fi
    ;;

  hermes)
    # Check for agent definition
    if [[ -f "$AGENT_DIR/AGENTS.md" ]]; then
      file_exists "AGENTS.md" "AGENTS.md"
      file_nonempty "AGENTS.md" "AGENTS.md"
    fi

    if [[ -f "$AGENT_DIR/SOUL.md" ]]; then
      file_exists "SOUL.md" "SOUL.md"
      file_nonempty "SOUL.md" "SOUL.md"
    fi

    if [[ -f "$AGENT_DIR/system-prompt.md" ]]; then
      file_exists "system-prompt.md" "system-prompt.md"
      file_nonempty "system-prompt.md" "system-prompt.md"
    fi

    if [[ -f "$AGENT_DIR/config.yaml" ]]; then
      valid_yaml "config.yaml" "config.yaml"
    fi

    if [[ -f "$AGENT_DIR/tool-definitions.json" ]]; then
      valid_json "tool-definitions.json" "tool-definitions.json"
    fi

    if [[ -f "$AGENT_DIR/MEMORY.md" ]]; then
      file_nonempty "MEMORY.md" "MEMORY.md"
    fi
    ;;

  *)
    check "Runtime detection" "FAIL" "Could not detect runtime. Use --runtime flag."
    ;;
esac

# --- Cross-runtime checks ---

# Memory directory structure
check_memory_structure

# Template residue (unresolved {{VARIABLE}} patterns)
check_template_residue

# File size sanity
check_file_sizes

# UTF-8 encoding
check_encoding

# Internal link/reference validation
check_internal_links

# Cross-file tool consistency
check_tool_consistency

# Guardrail coverage
check_guardrail_coverage

# Check for placeholder/TODO content (should be zero in production)
placeholder_count=0
if command -v grep &>/dev/null; then
  placeholder_count=$(grep -rlE "TODO|FIXME|PLACEHOLDER" "$AGENT_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
fi
if [[ "$placeholder_count" -gt 0 ]]; then
  check "No placeholders" "FAIL" "$placeholder_count files contain TODO/FIXME/PLACEHOLDER"
else
  check "No placeholders" "PASS" "No placeholder content found"
fi

# --- Output ---

echo ""
if [[ "$FORMAT" == "json" ]]; then
  echo "{"
  echo "  \"agent_dir\": \"$AGENT_DIR\","
  echo "  \"runtime\": \"$RUNTIME\","
  echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"summary\": {\"pass\": $PASS, \"fail\": $FAIL, \"warn\": $WARN},"
  echo "  \"checks\": ["
  first=true
  for result in "${RESULTS[@]}"; do
    IFS='|' read -r name status notes <<< "$result"
    if [[ "$first" == true ]]; then
      first=false
    else
      echo ","
    fi
    # Escape quotes in notes for valid JSON
    notes_escaped=$(echo "$notes" | sed 's/"/\\"/g')
    printf "    {\"check\": \"%s\", \"status\": \"%s\", \"notes\": \"%s\"}" "$name" "$status" "$notes_escaped"
  done
  echo ""
  echo "  ]"
  echo "}"
else
  echo "## Results"
  echo ""
  printf "| %-35s | %-6s | %-55s |\n" "Check" "Status" "Notes"
  printf "| %-35s | %-6s | %-55s |\n" "-----------------------------------" "------" "-------------------------------------------------------"
  for result in "${RESULTS[@]}"; do
    IFS='|' read -r name status notes <<< "$result"
    printf "| %-35s | %-6s | %-55s |\n" "$name" "$status" "${notes:0:55}"
  done
  echo ""
  echo "## Summary"
  echo ""
  echo "- PASS: $PASS"
  echo "- FAIL: $FAIL"
  echo "- WARN: $WARN"
  echo "- Total: $((PASS + FAIL + WARN))"
  echo ""

  if [[ "$FAIL" -eq 0 ]]; then
    echo "**Verdict: PASS** — All critical checks passed."
    if [[ "$WARN" -gt 0 ]]; then
      echo "($WARN warnings — review recommended)"
    fi
  else
    echo "**Verdict: FAIL** — $FAIL critical check(s) failed."
    echo ""
    echo "Failed checks:"
    for result in "${RESULTS[@]}"; do
      IFS='|' read -r name status notes <<< "$result"
      if [[ "$status" == "FAIL" ]]; then
        echo "  - $name: $notes"
      fi
    done
  fi
fi

# Exit code: 0 if no failures, 1 if any failures
[[ "$FAIL" -eq 0 ]]

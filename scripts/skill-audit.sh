#!/usr/bin/env bash
# skill-audit.sh — Audit installed skills for ASK agent builds
# Usage: ./scripts/skill-audit.sh [--format json|table] [--filter <keyword>]
#
# Scans installed skills across known locations and outputs a structured
# inventory for the /ask:research phase to evaluate.

set -euo pipefail

# --- Config ---
FORMAT="table"
FILTER=""
SKILL_LOCATIONS=(
  "$HOME/.claude/skills"
  "$HOME/.claude/get-shit-done/skills"
  ".claude/skills"
  ".agents/skills"
)

# --- Parse args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --format) FORMAT="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: skill-audit.sh [--format json|table] [--filter <keyword>]"
      echo ""
      echo "Scans installed skills and outputs inventory."
      echo ""
      echo "Options:"
      echo "  --format   Output format: table (default) or json"
      echo "  --filter   Filter skills by keyword in name or description"
      exit 0
      ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# --- Functions ---

extract_frontmatter_field() {
  local file="$1"
  local field="$2"
  # Extract YAML frontmatter field value (between --- delimiters)
  sed -n '/^---$/,/^---$/p' "$file" 2>/dev/null | grep -E "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//"
}

scan_skill_dir() {
  local dir="$1"
  local location_label="$2"

  [[ ! -d "$dir" ]] && return

  for skill_path in "$dir"/*/; do
    [[ ! -d "$skill_path" ]] && continue

    local skill_name
    skill_name=$(basename "$skill_path")

    # Look for SKILL.md, README.md, or any .md file for metadata
    local meta_file=""
    if [[ -f "$skill_path/SKILL.md" ]]; then
      meta_file="$skill_path/SKILL.md"
    elif [[ -f "$skill_path/README.md" ]]; then
      meta_file="$skill_path/README.md"
    fi

    local description="-"
    local version="-"
    local author="-"

    if [[ -n "$meta_file" ]]; then
      description=$(extract_frontmatter_field "$meta_file" "description")
      version=$(extract_frontmatter_field "$meta_file" "version")
      author=$(extract_frontmatter_field "$meta_file" "author")
      [[ -z "$description" ]] && description=$(head -5 "$meta_file" | grep -v "^---" | grep -v "^#" | head -1 | tr -d '\n')
      [[ -z "$description" ]] && description="-"
      [[ -z "$version" ]] && version="-"
      [[ -z "$author" ]] && author="-"
    fi

    # Count files in skill
    local file_count
    file_count=$(find "$skill_path" -type f | wc -l | tr -d ' ')

    # Apply filter
    if [[ -n "$FILTER" ]]; then
      if ! echo "$skill_name $description" | grep -qi "$FILTER"; then
        continue
      fi
    fi

    # Output
    if [[ "$FORMAT" == "json" ]]; then
      echo "{\"name\":\"$skill_name\",\"location\":\"$location_label\",\"description\":\"$description\",\"version\":\"$version\",\"author\":\"$author\",\"files\":$file_count,\"path\":\"$skill_path\"}"
    else
      printf "| %-25s | %-12s | %-45s | %-8s | %5s |\n" \
        "$skill_name" "$location_label" "${description:0:45}" "$version" "$file_count"
    fi
  done
}

# --- Main ---

echo "# Skill Audit"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# Count locations found
locations_found=0
for loc in "${SKILL_LOCATIONS[@]}"; do
  [[ -d "$loc" ]] && locations_found=$((locations_found + 1))
done

echo "Scanning $locations_found skill locations..."
echo ""

if [[ "$FORMAT" == "json" ]]; then
  echo "["
  first=true
  for loc in "${SKILL_LOCATIONS[@]}"; do
    if [[ -d "$loc" ]]; then
      label=$(basename "$(dirname "$loc")")/$(basename "$loc")
      while IFS= read -r line; do
        if [[ "$first" == true ]]; then
          first=false
        else
          echo ","
        fi
        printf "  %s" "$line"
      done < <(scan_skill_dir "$loc" "$label")
    fi
  done
  echo ""
  echo "]"
else
  printf "| %-25s | %-12s | %-45s | %-8s | %5s |\n" \
    "Skill" "Location" "Description" "Version" "Files"
  printf "| %-25s | %-12s | %-45s | %-8s | %5s |\n" \
    "-------------------------" "------------" "---------------------------------------------" "--------" "-----"

  total=0
  for loc in "${SKILL_LOCATIONS[@]}"; do
    if [[ -d "$loc" ]]; then
      label=$(basename "$(dirname "$loc")")/$(basename "$loc")
      count_before=$total
      while IFS= read -r line; do
        echo "$line"
        total=$((total + 1))
      done < <(scan_skill_dir "$loc" "$label")
    fi
  done

  echo ""
  echo "Total skills found: $total"
fi

# Summary of locations
echo ""
echo "## Locations scanned"
for loc in "${SKILL_LOCATIONS[@]}"; do
  if [[ -d "$loc" ]]; then
    count=$(find "$loc" -maxdepth 1 -type d | tail -n +2 | wc -l | tr -d ' ')
    echo "  [x] $loc ($count skills)"
  else
    echo "  [ ] $loc (not found)"
  fi
done

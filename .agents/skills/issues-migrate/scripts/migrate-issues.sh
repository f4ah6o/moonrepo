#!/usr/bin/env bash
set -euo pipefail

# migrate-issues.sh - Migrate GitHub Issues to local issues/ directory
# Usage: bash migrate-issues.sh <repo_name>|--path <repo_path> [--force] [--dry-run] [--skip-agents] [--skip-readme] [--skip-close]

usage() {
  cat <<'EOF'
Usage: migrate-issues.sh <repo_name>|--path <repo_path> [options]

Options:
  --force          Overwrite existing issue files
  --path PATH      Use an explicit repo/worktree path
  --dry-run        Show planned changes without writing or closing
  --skip-agents    Skip updating AGENTS.md / CLAUDE.md
  --skip-readme    Skip updating README.md
  --skip-close     Skip closing issues on GitHub (only create local files)
  -h, --help       Show this help

Example:
  bash migrate-issues.sh mhx.mbt
  bash migrate-issues.sh mhx.mbt --force
  bash migrate-issues.sh mhx.mbt --dry-run
EOF
  exit 0
}

# --- argument parsing ---
REPO_NAME=""
REPO_PATH=""
FORCE=0
DRY_RUN=0
SKIP_AGENTS=0
SKIP_README=0
SKIP_CLOSE=0

while (($# > 0)); do
  case "$1" in
    -h|--help) usage ;;
    --force) FORCE=1 ;;
    --path)
      shift
      if [[ -z "${1:-}" ]]; then
        echo "--path requires a value" >&2
        exit 1
      fi
      REPO_PATH="$1"
      ;;
    --dry-run) DRY_RUN=1 ;;
    --skip-agents) SKIP_AGENTS=1 ;;
    --skip-readme) SKIP_README=1 ;;
    --skip-close) SKIP_CLOSE=1 ;;
    -*)
      echo "unknown option: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$REPO_NAME" ]]; then
        REPO_NAME="$1"
      else
        echo "unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
  shift
done

if [[ -z "$REPO_NAME" && -z "$REPO_PATH" ]]; then
  echo "missing repo name" >&2
  usage
fi

if [[ -z "$REPO_PATH" ]]; then
  REPO_PATH="target-repos/${REPO_NAME}.git/.wt/main"
fi
if [[ ! -d "$REPO_PATH" ]]; then
  echo "repo path not found: $REPO_PATH" >&2
  exit 1
fi
if [[ ! -e "$REPO_PATH/.git" ]]; then
  echo "not a git repo: $REPO_PATH" >&2
  exit 1
fi

# --- resolve GitHub slug ---
REPO_SLUG="$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null | sed -e 's#^git@github.com:##' -e 's#^https://github.com/##' -e 's#^http://github.com/##' -e 's#\.git$##' || true)"
if [[ -z "$REPO_SLUG" ]]; then
  echo "cannot resolve GitHub slug from remote origin" >&2
  exit 1
fi

echo "repo:  $REPO_SLUG"
echo "path:  $REPO_PATH"
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "mode:  dry-run"
fi

# --- slugify title for filename ---
slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]/-/g' \
    | sed -e 's/--*/-/g' \
    | sed -e 's/^-//' -e 's/-$//' \
    | cut -c1-50
}

# --- infer category from labels ---
infer_category() {
  local labels="$1"
  if printf '%s' "$labels" | jq -e 'map(.name | ascii_downcase) | any(. == "bug")' > /dev/null 2>&1; then
    printf 'bug'
  elif printf '%s' "$labels" | jq -e 'map(.name | ascii_downcase) | any(. == "enhancement")' > /dev/null 2>&1; then
    printf 'enhance'
  elif printf '%s' "$labels" | jq -e 'map(.name | ascii_downcase) | any(. == "documentation")' > /dev/null 2>&1; then
    printf 'docs'
  else
    printf 'spec'
  fi
}

# --- timestamp from ISO 8601 (colon-free) ---
to_file_time() {
  local raw="$1"
  local ts

  ts="$(printf '%s' "$raw" | sed -e 's/\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)T\([0-9]\{2\}\):\([0-9]\{2\}\):\([0-9]\{2\}\).*/\1T\2\3\4/' -e 's/Z$//')"
  if [[ "$ts" != "$raw" ]]; then
    printf '%s' "$ts"
    return
  fi

  date -jf '%Y-%m-%dT%H:%M:%SZ' "$raw" '+%Y-%m-%dT%H%M%S' 2>/dev/null \
    || printf '%s' "$raw" | tr -d ':-' | cut -c1-15
}

# --- directories ---
ISSUES_DIR="$REPO_PATH/issues"
CLOSED_DIR="$ISSUES_DIR/closed"
PENDING_DIR="$ISSUES_DIR/pending"

if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$ISSUES_DIR" "$CLOSED_DIR" "$PENDING_DIR"
else
  echo "  [dry-run] would mkdir: $ISSUES_DIR $CLOSED_DIR $PENDING_DIR"
fi

# --- fetch issues ---
fetch_issues() {
  local state="$1"
  local fields="number,title,body,labels,createdAt"
  local csv

  if [[ "$state" == "closed" ]]; then
    fields="$fields,closedAt"
  fi

  gh issue list -R "$REPO_SLUG" --state "$state" -L 1000 --json "$fields" 2>/dev/null || echo '[]'
}

echo ""
echo "fetching open issues..."
OPEN_JSON="$(fetch_issues open)"
echo "fetching closed issues..."
CLOSED_JSON="$(fetch_issues closed)"

OPEN_COUNT="$(printf '%s' "$OPEN_JSON" | jq 'length')"
CLOSED_COUNT="$(printf '%s' "$CLOSED_JSON" | jq 'length')"
echo "open: $OPEN_COUNT, closed: $CLOSED_COUNT"

# --- process a single issue ---
created=0
updated=0
skipped=0

process_issue() {
  local state="$1"     # open or closed
  local json="$2"      # single issue JSON object

  local number title body labels createdAt closedAt
  number="$(printf '%s' "$json" | jq -r '.number')"
  title="$(printf '%s' "$json" | jq -r '.title')"
  body="$(printf '%s' "$json" | jq -r '.body // ""')"
  labels="$(printf '%s' "$json" | jq -c '.labels // []')"
  createdAt="$(printf '%s' "$json" | jq -r '.createdAt // ""')"
  closedAt="$(printf '%s' "$json" | jq -r '.closedAt // ""')"

  local category slug timestamp
  slug="$(slugify "$title")"
  category="$(infer_category "$labels")"
  timestamp="$(to_file_time "$createdAt")"

  local filename="${timestamp}-${category}-${slug}.md"

  local dir="$ISSUES_DIR"
  if [[ "$state" == "closed" ]]; then
    dir="$CLOSED_DIR"
  fi

  local filepath="$dir/$filename"

  if [[ -f "$filepath" && "$FORCE" -eq 0 ]]; then
    echo "  skip (exists): #$number → $filename"
    skipped=$((skipped + 1))
    return
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] would create: $dir/$filename  (GH #$number, state=$state)"
    created=$((created + 1))
    return
  fi

  created=$((created + 1))
  if [[ -f "$filepath" ]]; then
    updated=$((updated + 1))
    created=$((created - 1))
  fi

  # --- markdown content ---
  cat > "$filepath" <<MDEOF
# $title

Created: $(printf '%s' "$createdAt" | cut -c1-10)
$([ -n "$closedAt" ] && printf 'Completed: %s\n' "$(printf '%s' "$closedAt" | cut -c1-10)")
Model: gh-migrate

## Summary

$title

## Original Issue

- [GitHub #$number](https://github.com/$REPO_SLUG/issues/$number)
$([ -n "$labels" ] && printf '%s' "$labels" | jq -r 'map("- labeled: `\(.name)`") | join("\n")')

## Description

$body
MDEOF

  echo "  created: $filepath  (GH #$number, state=$state)"

  # --- close on GitHub ---
  if [[ "$state" == "open" && "$SKIP_CLOSE" -eq 0 ]]; then
    gh issue comment "$number" -R "$REPO_SLUG" \
      -b "Migrated to local \`issues/\` directory. Closing." \
      >/dev/null 2>&1 || true
    gh issue close "$number" -R "$REPO_SLUG" >/dev/null 2>&1 || true
    echo "    GH #$number closed"
  fi
}

# --- process all issues ---
echo ""
echo "processing open issues..."
printf '%s' "$OPEN_JSON" | jq -c '.[]' 2>/dev/null | while IFS= read -r issue; do
  [[ -n "$issue" ]] || continue
  process_issue "open" "$issue"
done

echo ""
echo "processing closed issues..."
printf '%s' "$CLOSED_JSON" | jq -c '.[]' 2>/dev/null | while IFS= read -r issue; do
  [[ -n "$issue" ]] || continue
  process_issue "closed" "$issue"
done

echo ""
echo "---"
echo "created: $created (updated: $updated, skipped: $skipped)"

# --- update AGENTS.md / CLAUDE.md ---
SKILL_DIR=".agents/skills/issues-migrate"
AGENTS_TEMPLATE="$SKILL_DIR/references/agents-issues-section.md"
README_TEMPLATE="$SKILL_DIR/references/readme-issues-section.md"

append_section_if_missing() {
  local file="$1"
  local marker="$2"
  local template="$3"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] would update: $file"
    return
  fi

  if [[ ! -f "$file" ]]; then
    echo "  (no $file, skipping)"
    return
  fi

  if grep -Fq "$marker" "$file" 2>/dev/null; then
    echo "  skip $file (already has issues section)"
    return
  fi

  cat "$template" >> "$file"
  echo "  updated: $file"
}

if [[ "$SKIP_AGENTS" -eq 0 && -f "$AGENTS_TEMPLATE" ]]; then
  for f in "$REPO_PATH/AGENTS.md" "$REPO_PATH/CLAUDE.md"; do
    [[ -f "$f" ]] || continue
    append_section_if_missing "$f" "## issues について" "$AGENTS_TEMPLATE"
  done
fi

if [[ "$SKIP_README" -eq 0 && -f "$README_TEMPLATE" ]]; then
  for f in "$REPO_PATH/README.md" "$REPO_PATH/README.mbt.md"; do
    [[ -f "$f" ]] || continue
    append_section_if_missing "$f" "## Issue Management" "$README_TEMPLATE"
  done
fi

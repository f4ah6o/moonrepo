#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=repo-lib.sh
source "$script_dir/repo-lib.sh"

OWNER="${OWNER:-f4ah6o}"
REPOS_DIR="${REPOS_DIR:-repos}"
APPLY="${APPLY:-0}"
VERSION="${VERSION:-}"

usage() {
  cat >&2 <<'EOF'
Usage:
  VERSION=<ver> [APPLY=1] bash scripts/moonbit-bump.sh
  bash scripts/moonbit-bump.sh --scan-only

Env:
  OWNER      GitHub owner (default: f4ah6o)
  REPOS_DIR  Local clones dir (default: repos)
EOF
}

SCAN_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --scan-only) SCAN_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $arg" >&2; usage; exit 1 ;;
  esac
done

if [[ "$SCAN_ONLY" -eq 0 && -z "$VERSION" ]]; then
  echo "VERSION is required (or pass --scan-only)" >&2
  exit 1
fi

tool_versions_line() {
  local path="$1"
  [[ -f "$path/.tool-versions" ]] || { echo "(none)"; return; }
  awk '/^moonbit[[:space:]]+/ {print; found=1} END {if (!found) print "(no moonbit line)"}' "$path/.tool-versions"
}

workflow_install_lines() {
  local path="$1"
  local wfdir="$path/.github/workflows"
  [[ -d "$wfdir" ]] || return 0
  shopt -s nullglob
  local f
  for f in "$wfdir"/*.yml "$wfdir"/*.yaml; do
    [[ -f "$f" ]] || continue
    local rel="${f#$path/}"
    { grep -n "cli\.moonbitlang\.com/install/unix\.sh" "$f" 2>/dev/null || true; } | while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      printf '  [%s] %s\n' "$rel" "$line"
    done
  done
}

render_tool_versions() {
  local path="$1"
  local ver="$2"
  if [[ -f "$path/.tool-versions" ]]; then
    awk -v v="$ver" '
      /^moonbit[[:space:]]+/ { print "moonbit " v; seen=1; next }
      { print }
      END { if (!seen) print "moonbit " v }
    ' "$path/.tool-versions"
  else
    printf 'moonbit %s\n' "$ver"
  fi
}

bump_tool_versions() {
  local path="$1"
  local ver="$2"
  local apply="$3"
  local target="$path/.tool-versions"
  local new
  new="$(render_tool_versions "$path" "$ver")"

  local old=""
  [[ -f "$target" ]] && old="$(cat "$target")"

  if [[ "$old" == "$new" ]]; then
    printf '  [.tool-versions]             unchanged (%s)\n' "$(tool_versions_line "$path" | tr -d '\n')"
    return 0
  fi

  if [[ "$apply" -eq 1 ]]; then
    printf '%s\n' "$new" > "$target"
    printf '  [.tool-versions]             written: moonbit %s\n' "$ver"
  else
    if [[ -z "$old" ]]; then
      printf '  [.tool-versions]             + moonbit %s (new file)\n' "$ver"
    else
      printf '  [.tool-versions]\n'
      diff -u <(printf '%s\n' "$old") <(printf '%s\n' "$new") | sed 's/^/    /' || true
    fi
  fi
}

bump_workflow_file() {
  local file="$1"
  local ver="$2"
  local apply="$3"
  local rel="$4"

  grep -q "cli\.moonbitlang\.com/install/unix\.sh" "$file" || return 0

  local tmp
  tmp="$(mktemp)"
  # Rewrites:
  #   (1) "... install/unix.sh | bash" without env → inject MOONBIT_INSTALL_VERSION
  #   (2) existing "... | MOONBIT_INSTALL_VERSION=<old> bash" → replace <old>
  sed -E \
    -e "s#(cli\\.moonbitlang\\.com/install/unix\\.sh[^|]*)\\|[[:space:]]*MOONBIT_INSTALL_VERSION=\"?[^[:space:]\"]+\"?[[:space:]]+bash#\\1| MOONBIT_INSTALL_VERSION=\"${ver}\" bash#g" \
    -e "s#(cli\\.moonbitlang\\.com/install/unix\\.sh[^|]*)\\|[[:space:]]*bash([[:space:]]|$)#\\1| MOONBIT_INSTALL_VERSION=\"${ver}\" bash\\2#g" \
    "$file" > "$tmp"

  if cmp -s "$file" "$tmp"; then
    printf '  [%s] unchanged\n' "$rel"
    rm -f "$tmp"
    return 0
  fi

  if [[ "$apply" -eq 1 ]]; then
    mv "$tmp" "$file"
    printf '  [%s] written\n' "$rel"
  else
    printf '  [%s]\n' "$rel"
    diff -u "$file" "$tmp" | sed 's/^/    /' || true
    rm -f "$tmp"
  fi
}

bump_workflows() {
  local path="$1"
  local ver="$2"
  local apply="$3"
  local wfdir="$path/.github/workflows"
  [[ -d "$wfdir" ]] || { printf '  [.github/workflows] (no workflows)\n'; return 0; }

  shopt -s nullglob
  local touched=0
  local f
  for f in "$wfdir"/*.yml "$wfdir"/*.yaml; do
    [[ -f "$f" ]] || continue
    if grep -q "cli\.moonbitlang\.com/install/unix\.sh" "$f"; then
      bump_workflow_file "$f" "$ver" "$apply" "${f#$path/}"
      touched=$((touched + 1))
    fi
  done
  if [[ "$touched" -eq 0 ]]; then
    printf '  [.github/workflows] (no moonbit install line)\n'
  fi
}

list_target_names() {
  gh repo list "$OWNER" --json name,repositoryTopics -L 1000 \
    --jq '.[] | select(.repositoryTopics[]?.name == "moonbit") | .name' | sort
}

names=()
while IFS= read -r _name; do
  [[ -n "$_name" ]] || continue
  names+=("$_name")
done < <(list_target_names)

planned=0
skipped_dirty=0
missing_clone=0
unchanged=0
failed=0

if [[ "${#names[@]}" -eq 0 ]]; then
  echo "no $OWNER repos with topic 'moonbit' found" >&2
  exit 1
fi

for name in "${names[@]}"; do
  [[ -n "$name" ]] || continue
  path="$REPOS_DIR/$name"
  slug="$OWNER/$name"

  if [[ ! -d "$path/.git" ]]; then
    echo "missing clone: $slug -> $path" >&2
    missing_clone=$((missing_clone + 1))
    continue
  fi

  if [[ "$SCAN_ONLY" -eq 1 ]]; then
    printf 'repo: %s (path: %s)\n' "$slug" "$path"
    printf '  [.tool-versions] %s\n' "$(tool_versions_line "$path")"
    workflow_install_lines "$path"
    continue
  fi

  if repo_is_dirty "$path"; then
    echo "skip dirty: $slug"
    skipped_dirty=$((skipped_dirty + 1))
    continue
  fi

  printf 'repo: %s (path: %s)\n' "$slug" "$path"
  bump_tool_versions "$path" "$VERSION" "$APPLY" || failed=$((failed + 1))
  bump_workflows     "$path" "$VERSION" "$APPLY" || failed=$((failed + 1))
  planned=$((planned + 1))
done

if [[ "$SCAN_ONLY" -eq 1 ]]; then
  echo "summary: scanned=${#names[@]} missing_clone=$missing_clone"
  exit 0
fi

mode="dry-run"
[[ "$APPLY" -eq 1 ]] && mode="apply"
echo "summary: mode=$mode planned=$planned skipped_dirty=$skipped_dirty missing_clone=$missing_clone failed=$failed"
[[ "$failed" -eq 0 ]]

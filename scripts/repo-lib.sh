#!/usr/bin/env bash
set -euo pipefail

REPO_LIST="${REPO_LIST:-repository.ini}"
REPOS_DIR="${REPOS_DIR:-repos}"
REPO_SCOPE="${REPO_SCOPE:-active}"

trim_line() {
  printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

repo_slug_from_remote_url() {
  local remote_url="$1"
  local repo

  repo="${remote_url#git@github.com:}"
  repo="${repo#https://github.com/}"
  repo="${repo#http://github.com/}"
  repo="${repo%.git}"
  printf '%s\n' "$repo"
}

repo_slug_from_path() {
  local path="$1"
  local remote_url

  remote_url="$(git -C "$path" remote get-url origin 2>/dev/null || true)"
  if [[ -z "$remote_url" ]]; then
    return 1
  fi

  repo_slug_from_remote_url "$remote_url"
}

repo_is_dirty() {
  local path="$1"
  [[ -n "$(git -C "$path" status --porcelain 2>/dev/null || true)" ]]
}

repo_ahead_count() {
  local path="$1"
  if ! git -C "$path" rev-parse --verify '@{upstream}' >/dev/null 2>&1; then
    printf '0\n'
    return 0
  fi

  git -C "$path" rev-list --count '@{upstream}..HEAD' 2>/dev/null || printf '0\n'
}

repo_is_moon() {
  local path="$1"
  [[ -f "$path/moon.mod.json" ]]
}

list_active_repo_entries() {
  if [[ ! -f "$REPO_LIST" ]]; then
    echo "missing $REPO_LIST" >&2
    return 1
  fi

  awk '
    function trim(s) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
      return s
    }
    {
      line = trim($0)
      if (line == "" || line ~ /^[#;]/) {
        next
      }
      if (line !~ /^[^\/[:space:]]+\/[^\/[:space:]]+$/) {
        printf "invalid repository.ini line: %s\n", line > "/dev/stderr"
        invalid = 1
        next
      }
      name = line
      sub(/^.*\//, "", name)
      printf "%s\t%s\t%s/%s\n", line, name, repos_dir, name
    }
    END {
      if (invalid) {
        exit 1
      }
    }
  ' repos_dir="$REPOS_DIR" "$REPO_LIST"
}

list_cloned_repo_entries() {
  local dir
  local name
  local repo

  shopt -s nullglob
  for dir in "$REPOS_DIR"/*; do
    [[ -d "$dir/.git" ]] || continue
    name="$(basename "$dir")"
    repo="$name"
    if repo="$(repo_slug_from_path "$dir")"; then
      :
    else
      repo="$name"
    fi
    printf '%s\t%s\t%s\n' "$repo" "$name" "$dir"
  done | sort
}

list_target_repo_entries() {
  case "$REPO_SCOPE" in
    active) list_active_repo_entries ;;
    cloned) list_cloned_repo_entries ;;
    *)
      echo "unknown REPO_SCOPE: $REPO_SCOPE" >&2
      return 1
      ;;
  esac
}

list_extra_cloned_repo_entries() {
  local -A active_names=()
  local repo
  local name
  local path

  while IFS=$'\t' read -r repo name path; do
    active_names["$name"]=1
  done < <(list_active_repo_entries)

  while IFS=$'\t' read -r repo name path; do
    [[ -n "${active_names[$name]:-}" ]] && continue
    printf '%s\t%s\t%s\n' "$repo" "$name" "$path"
  done < <(list_cloned_repo_entries)
}

validate_repo_list() {
  local -A seen_repo=()
  local -A seen_name=()
  local ok=1
  local repo
  local name
  local path

  while IFS=$'\t' read -r repo name path; do
    if [[ -n "${seen_repo[$repo]:-}" ]]; then
      echo "duplicate active repo: $repo" >&2
      ok=0
    fi
    seen_repo["$repo"]=1

    if [[ -n "${seen_name[$name]:-}" ]]; then
      echo "basename collision in active repos: $name" >&2
      ok=0
    fi
    seen_name["$name"]=1
  done < <(list_active_repo_entries)

  [[ "$ok" -eq 1 ]]
}

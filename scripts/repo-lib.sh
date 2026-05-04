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
  local base
  local name
  local repo
  local bare
  local worktree
  local seen=''
  local slug

  shopt -s nullglob
  for dir in "$REPOS_DIR"/*; do
    [[ -d "$dir" ]] || continue
    base="$(basename "$dir")"
    case "$base" in
      *.git) name="${base%.git}" ;;
      *)     name="$base" ;;
    esac
    case $'\n'"$seen"$'\n' in
      *$'\n'"$name"$'\n'*) continue ;;
    esac
    seen="${seen}${name}"$'\n'
    bare="$REPOS_DIR/$name.git"
    worktree="$REPOS_DIR/$name"
    [[ -d "$bare" || -e "$worktree/.git" ]] || continue
    repo="$name"
    if [[ -e "$worktree/.git" ]]; then
      if slug="$(repo_slug_from_path "$worktree")"; then repo="$slug"; fi
    elif [[ -d "$bare" ]]; then
      if slug="$(repo_slug_from_path "$bare")"; then repo="$slug"; fi
    fi
    printf '%s\t%s\t%s\n' "$repo" "$name" "$worktree"
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
  local active_names
  local repo
  local name
  local path

  active_names=''

  while IFS=$'\t' read -r repo name path; do
    active_names+="${name}"$'\n'
  done < <(list_active_repo_entries)

  while IFS=$'\t' read -r repo name path; do
    if printf '%s' "$active_names" | grep -Fqx "$name"; then
      continue
    fi
    printf '%s\t%s\t%s\n' "$repo" "$name" "$path"
  done < <(list_cloned_repo_entries)
}

validate_repo_list() {
  local seen_repo
  local seen_name
  local ok=1
  local repo
  local name
  local path

  seen_repo=''
  seen_name=''

  while IFS=$'\t' read -r repo name path; do
    if printf '%s' "$seen_repo" | grep -Fqx "$repo"; then
      echo "duplicate active repo: $repo" >&2
      ok=0
    fi
    seen_repo+="${repo}"$'\n'

    if printf '%s' "$seen_name" | grep -Fqx "$name"; then
      echo "basename collision in active repos: $name" >&2
      ok=0
    fi
    seen_name+="${name}"$'\n'
  done < <(list_active_repo_entries)

  [[ "$ok" -eq 1 ]]
}

#!/usr/bin/env bash
set -euo pipefail

REPO_LIST="${REPO_LIST:-repository.ini}"
REPOS_DIR="${REPOS_DIR:-target-repos}"
REPO_SCOPE="${REPO_SCOPE:-active}"
DEFAULT_WORKTREE_NAME="${DEFAULT_WORKTREE_NAME:-main}"

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

repo_behind_count() {
  local path="$1"
  if ! git -C "$path" rev-parse --verify '@{upstream}' >/dev/null 2>&1; then
    printf '0\n'
    return 0
  fi

  git -C "$path" rev-list --count 'HEAD..@{upstream}' 2>/dev/null || printf '0\n'
}

repo_gitdir_path() {
  local dir="$1"
  local gitfile="$dir/.git"
  local target parent

  if [[ -d "$gitfile" ]]; then
    printf '%s\n' "$gitfile"
    return 0
  fi
  if [[ ! -f "$gitfile" ]]; then
    return 1
  fi

  target="$(awk '/^gitdir:/ {sub(/^gitdir:[[:space:]]*/, ""); print; exit}' "$gitfile" 2>/dev/null || true)"
  [[ -n "$target" ]] || return 1
  if [[ "$target" != /* ]]; then
    parent="$(cd "$dir" && dirname "$target")"
    target="$(cd "$dir/$parent" && pwd)/$(basename "$target")"
  fi
  printf '%s\n' "$target"
}

repo_bare_name() {
  local dir="$1"
  local base

  if base="$(repo_bare_dir "$dir" 2>/dev/null)"; then
    base="$(basename "$base")"
    base="${base%.git}"
    [[ -n "$base" ]] || return 1
    printf '%s\n' "$base"
    return 0
  fi
  return 1
}

repo_bare_dir() {
  local dir="$1"
  local target

  if [[ -d "$dir" && "$(basename "$dir")" == *.git ]]; then
    printf '%s\n' "$dir"
    return 0
  fi

  target="$(repo_gitdir_path "$dir")" || return 1
  case "$target" in
    */worktrees/*) target="${target%/worktrees/*}" ;;
  esac
  printf '%s\n' "$target"
}

repo_bare_path_from_name() {
  local name="$1"
  printf '%s/%s.git\n' "$REPOS_DIR" "$name"
}

repo_main_worktree_path_from_name() {
  local name="$1"
  printf '%s/%s.git/.wt/%s\n' "$REPOS_DIR" "$name" "$DEFAULT_WORKTREE_NAME"
}

repo_is_moon() {
  local path="$1"
  [[ -f "$path/moon.mod.json" ]]
}

repo_current_branch() {
  local path="$1"
  git -C "$path" rev-parse --abbrev-ref HEAD 2>/dev/null
}

repo_upstream_ref() {
  local path="$1"
  git -C "$path" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null
}

repo_default_branch() {
  local path="$1"
  local ref

  ref="$(git -C "$path" symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [[ -z "$ref" ]]; then
    ref="$(git -C "$path" symbolic-ref HEAD 2>/dev/null || true)"
  fi
  [[ -n "$ref" ]] || return 1
  ref="${ref#refs/heads/}"
  printf '%s\n' "${ref#refs/remotes/origin/}"
}

repo_branch_exists() {
  local path="$1"
  local branch="$2"
  local bare

  bare="$(repo_bare_dir "$path")" || return 1
  git -C "$bare" show-ref --verify --quiet "refs/heads/$branch"
}

repo_remote_branch_exists() {
  local path="$1"
  local branch="$2"
  local bare

  bare="$(repo_bare_dir "$path")" || return 1
  git -C "$bare" show-ref --verify --quiet "refs/remotes/origin/$branch"
}

repo_worktree_exists() {
  local path="$1"
  local bare="$2"
  local candidate

  if [[ "$path" == /* ]]; then
    candidate="$path"
  else
    candidate="$(pwd)/$path"
  fi
  git -C "$bare" worktree list --porcelain \
    | awk '/^worktree / {sub(/^worktree /, ""); print}' \
    | grep -Fxq "$candidate"
}

codex_normalize_task_slug() {
  local raw="$1"
  local slug

  slug="$(printf '%s' "$raw" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's|[^a-z0-9._-]+|-|g; s|^[._-]+||; s|[._-]+$||; s|-+|-|g')"
  [[ -n "$slug" ]] || return 1
  printf '%s\n' "$slug"
}

codex_branch_name() {
  local raw="$1"
  local slug

  slug="$(codex_normalize_task_slug "$raw")" || return 1
  printf 'codex/%s\n' "$slug"
}

codex_worktree_name() {
  local repo_name="$1"
  local raw_slug="$2"
  local stamp="$3"
  local slug

  slug="$(codex_normalize_task_slug "$raw_slug")" || return 1
  printf '%s-%s-%s\n' "$repo_name" "$slug" "$stamp"
}

codex_manifest_path() {
  local tasks_dir="$1"
  local repo_name="$2"
  local raw_slug="$3"
  local slug

  slug="$(codex_normalize_task_slug "$raw_slug")" || return 1
  printf '%s/%s-%s.json\n' "$tasks_dir" "$repo_name" "$slug"
}

codex_resolve_manifest_path() {
  local tasks_dir="$1"
  local repo_name="$2"
  local raw_slug="$3"
  local path

  path="$(codex_manifest_path "$tasks_dir" "$repo_name" "$raw_slug")" || return 1
  [[ -f "$path" ]] || return 1
  printf '%s\n' "$path"
}

update_manifest_status() {
  local manifest_path="$1"
  local status="$2"
  local tmp

  tmp="$(mktemp)"
  jq --arg status "$status" '.status = $status' "$manifest_path" >"$tmp"
  mv "$tmp" "$manifest_path"
}

repo_add_worktree() {
  local repo_path="$1"
  local worktree_path="$2"
  local branch="$3"
  local base_ref="$4"
  local bare
  local worktree_abs

  bare="$(repo_bare_dir "$repo_path")" || return 1
  if [[ -e "$worktree_path" ]]; then
    echo "worktree path already exists: $worktree_path" >&2
    return 1
  fi
  if repo_worktree_exists "$worktree_path" "$bare"; then
    echo "worktree already registered: $worktree_path" >&2
    return 1
  fi
  if repo_branch_exists "$repo_path" "$branch"; then
    echo "branch already exists: $branch" >&2
    return 1
  fi
  if repo_remote_branch_exists "$repo_path" "$branch"; then
    echo "remote branch already exists: origin/$branch" >&2
    return 1
  fi
  mkdir -p "$(dirname "$worktree_path")"
  worktree_abs="$(cd "$(dirname "$worktree_path")" && pwd)/$(basename "$worktree_path")"
  git -C "$bare" worktree add -b "$branch" "$worktree_abs" "$base_ref"
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
      printf "%s\t%s\t%s/%s.git/.wt/%s\n", line, name, repos_dir, name, default_worktree
    }
    END {
      if (invalid) {
        exit 1
      }
    }
  ' repos_dir="$REPOS_DIR" default_worktree="$DEFAULT_WORKTREE_NAME" "$REPO_LIST"
}

list_cloned_repo_entries() {
  local bare base name repo slug path

  shopt -s nullglob
  for bare in "$REPOS_DIR"/*.git; do
    [[ -d "$bare" ]] || continue
    base="$(basename "$bare")"
    name="${base%.git}"
    path="$bare/.wt/$DEFAULT_WORKTREE_NAME"
    [[ -e "$path/.git" ]] || continue
    repo="$name"
    if slug="$(repo_slug_from_path "$path" 2>/dev/null)"; then
      repo="$slug"
    fi
    printf '%s\t%s\t%s\n' "$repo" "$name" "$path"
  done | sort
}

list_orphan_bare_entries() {
  local bare base name repo slug path

  shopt -s nullglob
  for bare in "$REPOS_DIR"/*.git; do
    [[ -d "$bare" ]] || continue
    base="$(basename "$bare")"
    name="${base%.git}"
    path="$bare/.wt/$DEFAULT_WORKTREE_NAME"
    [[ -e "$path/.git" ]] && continue
    repo="$name"
    if slug="$(repo_slug_from_path "$bare" 2>/dev/null)"; then
      repo="$slug"
    fi
    printf '%s\t%s\t%s\n' "$repo" "$name" "$bare"
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

  while IFS=$'\t' read -r repo name path; do
    if printf '%s' "$active_names" | grep -Fqx "$name"; then
      continue
    fi
    printf '%s\t%s\t%s\n' "$repo" "$name" "$path"
  done < <(list_orphan_bare_entries)
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

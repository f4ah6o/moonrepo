#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
# shellcheck source=./repo-lib.sh
source "$script_dir/repo-lib.sh"

TASKS_DIR="${TASKS_DIR:-$repo_root/.codex/tasks}"

usage() {
  cat <<'EOF' >&2
usage:
  codex-task.sh start <repo> <task-slug>
  codex-task.sh status <repo> <task-slug>
  codex-task.sh pr <repo> <task-slug> [gh pr create args...]
  codex-task.sh health [--no-gh]
EOF
}

die() {
  echo "$*" >&2
  exit 1
}

normalize_repo_name() {
  local repo="${1##*/}"
  [[ -n "$repo" ]] || return 1
  printf '%s\n' "$repo"
}

repo_path_from_name() {
  local name="$1"
  repo_main_worktree_path_from_name "$name"
}

require_clone_path() {
  local repo_name="$1"
  local path

  path="$(repo_path_from_name "$repo_name")"
  if [[ ! -e "$path/.git" ]]; then
    die "missing worktree: $path"$'\n'"hint: add to $REPO_LIST and run \"just clone\""
  fi
  printf '%s\n' "$path"
}

require_repo_upstream() {
  local path="$1"
  if ! repo_upstream_ref "$path" >/dev/null 2>&1; then
    die "repo has no upstream: $path"
  fi
}

require_clean_repo() {
  local path="$1"
  repo_require_baseline_main "$path" \
    || die "baseline worktree is not ready for a codex task"$'\n'"hint: keep .wt/main clean on its default branch, then retry"
}

write_manifest() {
  local manifest_path="$1"
  local repo_name="$2"
  local worktree_path="$3"
  local branch="$4"
  local base="$5"
  local repo_slug="$6"

  mkdir -p "$(dirname "$manifest_path")"
  jq -n \
    --arg repo "$repo_name" \
    --arg repo_slug "$repo_slug" \
    --arg worktree "$worktree_path" \
    --arg branch "$branch" \
    --arg base "$base" \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg agent "codex" \
    --arg status "started" \
    '{
      repo: $repo,
      repo_slug: $repo_slug,
      worktree: $worktree,
      branch: $branch,
      base: $base,
      created_at: $created_at,
      agent: $agent,
      status: $status
    }' > "$manifest_path"
}

manifest_field() {
  local manifest_path="$1"
  local key="$2"
  jq -r --arg key "$key" '.[$key] // empty' "$manifest_path"
}

load_manifest() {
  local repo_name="$1"
  local task_slug="$2"
  local manifest_path

  manifest_path="$(codex_resolve_manifest_path "$TASKS_DIR" "$repo_name" "$task_slug")" \
    || die "missing manifest: $(codex_manifest_path "$TASKS_DIR" "$repo_name" "$task_slug")"$'\n'"hint: run \"just codex-start $repo_name $task_slug\" first"
  printf '%s\n' "$manifest_path"
}

print_worker_prompt() {
  local repo_name="$1"
  local worktree_path="$2"
  local branch="$3"
  local manifest_path="$4"

  cat <<EOF
manifest: $manifest_path
repo:     $repo_name
worktree: $worktree_path
branch:   $branch
agent:    codex worker

codex parent-thread prompt:
  Spawn exactly one worker sub agent for $worktree_path.
  The worker owns all edits inside that worktree and does the repository implementation work.
  If the target repo is a MoonBit repo, the worker must use moonbit-agent-guide before implementation; if the task changes MoonBit APIs, package structure, or refactors code, also use moonbit-refactoring.
  When running an opencode-review-loop for MoonBit work, include the same MoonBit skill requirement in the opencode implementation/review prompts and require review until exact LGTM.
  The parent thread must stay in moonrepo, perform orchestration only, then review, verify, push, and open the PR after the worker finishes.
  If ral is installed, use it only for short parent/reviewer messages; keep task state in this manifest, git, and GitHub.
EOF
}

branch_protection_json() {
  local repo_slug="$1"
  local base_branch="$2"
  gh api "repos/$repo_slug/branches/$base_branch/protection" 2>/dev/null || return 1
}

verify_required_checks() {
  local repo_slug="$1"
  local base_branch="$2"
  local worktree_path="$3"
  local sha status_json protection_json checks_json contexts_json failures missing required_count=0

  if ! protection_json="$(branch_protection_json "$repo_slug" "$base_branch")"; then
    echo "checks: branch protection unavailable or not enabled; skipping required-check verification"
    return 0
  fi

  checks_json="$(jq -c '
    [
      (.required_status_checks.contexts // [] | map({kind: "status", name: .})),
      (.required_status_checks.checks // [] | map({kind: "check", name: .context}))
    ] | add | unique_by(.kind + ":" + .name)
  ' <<<"$protection_json")"
  required_count="$(jq 'length' <<<"$checks_json")"
  if [[ "$required_count" -eq 0 ]]; then
    echo "checks: no required checks configured on $base_branch"
    return 0
  fi

  sha="$(git -C "$worktree_path" rev-parse HEAD)"
  status_json="$(gh api "repos/$repo_slug/commits/$sha/status" 2>/dev/null || true)"
  contexts_json="$(gh api "repos/$repo_slug/commits/$sha/check-runs" -H "Accept: application/vnd.github+json" 2>/dev/null || true)"

  failures="$(
    jq -r \
      --argjson required "$checks_json" \
      --argjson statuses "${status_json:-{\"statuses\":[]}}" \
      --argjson checks "${contexts_json:-{\"check_runs\":[]}}" '
      def status_state($name):
        ($statuses.statuses // [] | map(select(.context == $name)) | first | .state) // "missing";
      def check_state($name):
        ($checks.check_runs // [] | map(select(.name == $name)) | first) as $run
        | if $run == null then
            "missing"
          elif ($run.status // "") != "completed" then
            "pending"
          else
            ($run.conclusion // "missing")
          end;
      $required[]
      | .state =
          (if .kind == "status" then status_state(.name) else check_state(.name) end)
      | select(
          (.kind == "status" and .state != "success")
          or
          (.kind == "check" and (.state != "success" and .state != "neutral" and .state != "skipped"))
        )
      | "\(.kind)\t\(.name)\t\(.state)"
    ' <<<"{}"
  )"

  if [[ -n "$failures" ]]; then
    echo "required checks are not green for $repo_slug@$sha:" >&2
    while IFS=$'\t' read -r kind name state; do
      [[ -n "$kind" ]] || continue
      echo "  - $kind $name: $state" >&2
    done <<<"$failures"
    return 1
  fi

  echo "checks: all $required_count required checks passed for $sha"
}

start_cmd() {
  local repo_name raw_slug repo_path default_branch base_ref branch_name worktree_name
  local worktree_path manifest_path repo_slug bare_dir

  [[ $# -eq 2 ]] || die "usage: codex-task.sh start <repo> <task-slug>"
  repo_name="$(normalize_repo_name "$1")"
  raw_slug="$2"
  repo_path="$(require_clone_path "$repo_name")"
  require_clean_repo "$repo_path"
  require_repo_upstream "$repo_path"

  default_branch="$(repo_default_branch "$repo_path")" \
    || die "cannot determine origin/HEAD for $repo_path"
  base_ref="origin/$default_branch"
  branch_name="$(codex_branch_name "$raw_slug")"
  worktree_name="$(codex_worktree_name "$repo_name" "$raw_slug" "$(date +%Y%m%d)")"
  manifest_path="$(codex_manifest_path "$TASKS_DIR" "$repo_name" "$raw_slug")"
  repo_slug="$(repo_slug_from_path "$repo_path")" \
    || die "missing origin remote for $repo_path"
  bare_dir="$(repo_bare_dir "$repo_path")" \
    || die "cannot resolve bare repo for $repo_path"
  worktree_path="$bare_dir/.wt/codex/$(codex_normalize_task_slug "$raw_slug")"

  if [[ -e "$manifest_path" ]]; then
    die "manifest already exists: $manifest_path"
  fi

  git -C "$bare_dir" config wt.basedir .wt
  git -C "$bare_dir" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
  git -C "$bare_dir" fetch --quiet origin
  if ! git -C "$bare_dir" show-ref --verify --quiet "refs/remotes/origin/$default_branch"; then
    base_ref="$default_branch"
  fi
  repo_add_worktree "$repo_path" "$worktree_path" "$branch_name" "$base_ref"
  git -C "$worktree_path" branch --unset-upstream >/dev/null 2>&1 || true
  write_manifest "$manifest_path" "$repo_name" "$worktree_path" "$branch_name" "$default_branch" "$repo_slug"

  echo "created codex task"
  print_worker_prompt "$repo_name" "$worktree_path" "$branch_name" "$manifest_path"
}

status_cmd() {
  local repo_name raw_slug manifest_path worktree_path branch base status created_at repo_slug
  local current_branch upstream ahead behind anomalies=0

  [[ $# -eq 2 ]] || die "usage: codex-task.sh status <repo> <task-slug>"
  repo_name="$(normalize_repo_name "$1")"
  raw_slug="$2"
  manifest_path="$(load_manifest "$repo_name" "$raw_slug")"
  worktree_path="$(manifest_field "$manifest_path" worktree)"
  branch="$(manifest_field "$manifest_path" branch)"
  base="$(manifest_field "$manifest_path" base)"
  status="$(manifest_field "$manifest_path" status)"
  created_at="$(manifest_field "$manifest_path" created_at)"
  repo_slug="$(manifest_field "$manifest_path" repo_slug)"

  echo "manifest:   $manifest_path"
  echo "repo:       $repo_name"
  echo "repo_slug:  $repo_slug"
  echo "worktree:   $worktree_path"
  echo "branch:     $branch"
  echo "base:       $base"
  echo "status:     $status"
  echo "created_at: $created_at"

  if [[ ! -e "$worktree_path/.git" ]]; then
    echo "anomaly: missing worktree: $worktree_path" >&2
    return 1
  fi

  current_branch="$(repo_current_branch "$worktree_path" || true)"
  upstream="$(repo_upstream_ref "$worktree_path" || true)"
  ahead="$(repo_ahead_count "$worktree_path")"
  behind="$(repo_behind_count "$worktree_path")"

  echo "current_branch: $current_branch"
  echo "upstream:       ${upstream:-<none>}"
  echo "dirty:          $(if repo_is_dirty "$worktree_path"; then echo yes; else echo no; fi)"
  echo "ahead:          $ahead"
  echo "behind:         $behind"

  if [[ "$current_branch" != "$branch" ]]; then
    echo "anomaly: current branch does not match manifest branch" >&2
    anomalies=1
  fi
  if ! repo_branch_exists "$worktree_path" "$branch"; then
    echo "anomaly: branch not found in bare repo: $branch" >&2
    anomalies=1
  fi

  [[ "$anomalies" -eq 0 ]]
}

pr_cmd() {
  local repo_name raw_slug manifest_path worktree_path branch base repo_slug
  local title="" body="" body_file="" has_title=0 has_body=0
  local extra_args=() commits tmp_body upstream

  [[ $# -ge 2 ]] || die "usage: codex-task.sh pr <repo> <task-slug> [gh pr create args...]"
  repo_name="$(normalize_repo_name "$1")"
  raw_slug="$2"
  shift 2
  manifest_path="$(load_manifest "$repo_name" "$raw_slug")"
  worktree_path="$(manifest_field "$manifest_path" worktree)"
  branch="$(manifest_field "$manifest_path" branch)"
  base="$(manifest_field "$manifest_path" base)"
  repo_slug="$(manifest_field "$manifest_path" repo_slug)"

  [[ -e "$worktree_path/.git" ]] || die "missing worktree: $worktree_path"
  [[ "$(repo_current_branch "$worktree_path")" == "$branch" ]] || die "current branch mismatch: expected $branch"
  repo_is_dirty "$worktree_path" && die "worktree is dirty: $worktree_path"
  upstream="$(repo_upstream_ref "$worktree_path" || true)"
  [[ -n "$upstream" ]] || die "no upstream configured for $branch"$'\n'"hint: push the branch first with \"git -C $worktree_path push -u origin $branch\""

  gh auth status >/dev/null 2>&1 || die "gh auth status failed"
  verify_required_checks "$repo_slug" "$base" "$worktree_path"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)
        has_title=1
        title="${2:-}"
        [[ -n "$title" ]] || die "--title requires a value"
        extra_args+=("$1" "$2")
        shift 2
        ;;
      --body)
        has_body=1
        body="${2:-}"
        [[ -n "$body" ]] || die "--body requires a value"
        extra_args+=("$1" "$2")
        shift 2
        ;;
      --body-file)
        has_body=1
        body_file="${2:-}"
        [[ -n "$body_file" ]] || die "--body-file requires a value"
        extra_args+=("$1" "$2")
        shift 2
        ;;
      *)
        extra_args+=("$1")
        shift
        ;;
    esac
  done

  if [[ "$has_title" -eq 0 ]]; then
    title="$repo_name: ${raw_slug//-/ }"
  fi

  tmp_body=''
  if [[ "$has_body" -eq 0 ]]; then
    commits="$(git -C "$worktree_path" log --format='- %s' "origin/$base..HEAD" 2>/dev/null || true)"
    [[ -n "$commits" ]] || commits='- no new commits found'
    tmp_body="$(mktemp)"
    trap 'rm -f "$tmp_body"' RETURN
    cat >"$tmp_body" <<EOF
## Summary

$commits

## Verification

- TODO: describe verification performed in $worktree_path
EOF
    extra_args+=(--body-file "$tmp_body")
  fi

  if [[ "$has_title" -eq 0 ]]; then
    extra_args+=(--title "$title")
  fi

  (
    cd "$worktree_path"
    gh pr create --draft --base "$base" --head "$branch" "${extra_args[@]}"
  )

  update_manifest_status "$manifest_path" "pr_opened"
  rm -f "$tmp_body"
  trap - RETURN
}

manifest_task_slug() {
  local manifest_path="$1"
  local repo_name="$2"
  local file slug

  file="$(basename "$manifest_path")"
  slug="${file%.json}"
  slug="${slug#"$repo_name"-}"
  printf '%s\n' "$slug"
}

health_print_finding() {
  local repo_name="$1"
  local task_slug="$2"
  local status="$3"
  local finding="$4"
  local suggestion="$5"

  printf 'repo=%s task=%s status=%s finding=%s suggestion=%s\n' \
    "$repo_name" "$task_slug" "$status" "$finding" "$suggestion"
}

health_changed_paths() {
  local worktree_path="$1"
  local base="$2"
  local branch="$3"
  local base_ref

  base_ref="origin/$base"
  if ! git -C "$worktree_path" rev-parse --verify "$base_ref" >/dev/null 2>&1; then
    base_ref="$base"
  fi

  git -C "$worktree_path" diff --name-only "$base_ref...$branch" 2>/dev/null \
    || git -C "$worktree_path" diff --name-only "$base_ref..$branch" 2>/dev/null \
    || true
}

health_branch_patch_equivalent() {
  local worktree_path="$1"
  local base="$2"
  local branch="$3"
  local base_ref cherry

  base_ref="origin/$base"
  if ! git -C "$worktree_path" rev-parse --verify "$base_ref" >/dev/null 2>&1; then
    base_ref="$base"
  fi

  if git -C "$worktree_path" merge-base --is-ancestor "$branch" "$base_ref" >/dev/null 2>&1; then
    return 0
  fi

  cherry="$(git -C "$worktree_path" cherry "$base_ref" "$branch" 2>/dev/null || true)"
  [[ -n "$cherry" ]] || return 1
  ! grep -q '^+' <<<"$cherry"
}

health_pr_state() {
  local repo_slug="$1"
  local branch="$2"

  gh pr list \
    --repo "$repo_slug" \
    --head "$branch" \
    --state all \
    --json number,state,mergedAt,url \
    --limit 1 \
    --jq '.[0] // empty | if . == "" then "missing" else "\(.state)\t\(.mergedAt // "")\t\(.url)" end' \
    2>/dev/null || true
}

health_compact_path_list() {
  local path_file="$1"
  local limit="${2:-12}"
  local count sample

  count="$(wc -l <"$path_file" | tr -d '[:space:]')"
  sample="$(awk -v limit="$limit" 'NR <= limit { printf "%s%s", sep, $0; sep=", " }' "$path_file")"
  if [[ "$count" -gt "$limit" ]]; then
    printf '%s (+%s more)' "$sample" "$((count - limit))"
  else
    printf '%s' "$sample"
  fi
}

health_cmd() {
  local use_gh=1 manifest_path repo_name task_slug worktree_path branch base status repo_slug
  local findings=0 scanned=0 tmpdir gh_available=0 active_index active_paths
  local current_branch pr_state pr_status pr_merged pr_url

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-gh)
        use_gh=0
        shift
        ;;
      *)
        die "usage: codex-task.sh health [--no-gh]"
        ;;
    esac
  done

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN
  active_index="$tmpdir/active.tsv"
  active_paths="$tmpdir/paths"
  mkdir -p "$active_paths"
  : >"$active_index"

  if [[ "$use_gh" -eq 1 ]] && command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    gh_available=1
  fi

  echo "codex health"
  echo "tasks_dir: $TASKS_DIR"
  echo "github:    $(if [[ "$gh_available" -eq 1 ]]; then echo enabled; else echo disabled; fi)"
  echo

  shopt -s nullglob
  for manifest_path in "$TASKS_DIR"/*.json; do
    scanned=$((scanned + 1))
    repo_name="$(manifest_field "$manifest_path" repo)"
    worktree_path="$(manifest_field "$manifest_path" worktree)"
    branch="$(manifest_field "$manifest_path" branch)"
    base="$(manifest_field "$manifest_path" base)"
    status="$(manifest_field "$manifest_path" status)"
    repo_slug="$(manifest_field "$manifest_path" repo_slug)"
    task_slug="$(manifest_task_slug "$manifest_path" "$repo_name")"

    if [[ -z "$repo_name" || -z "$worktree_path" || -z "$branch" || -z "$base" ]]; then
      health_print_finding "${repo_name:-unknown}" "$task_slug" "${status:-unknown}" \
        "invalid manifest fields: $manifest_path" "inspect or recreate manifest"
      findings=$((findings + 1))
      continue
    fi

    if [[ ! -e "$worktree_path/.git" ]]; then
      health_print_finding "$repo_name" "$task_slug" "$status" \
        "missing worktree: $worktree_path" "remove stale manifest or restore worktree"
      findings=$((findings + 1))
      continue
    fi

    current_branch="$(repo_current_branch "$worktree_path" || true)"
    if [[ "$current_branch" != "$branch" ]]; then
      health_print_finding "$repo_name" "$task_slug" "$status" \
        "current branch is ${current_branch:-unknown}, expected $branch" \
        "inspect worktree branch"
      findings=$((findings + 1))
    fi

    if ! repo_branch_exists "$worktree_path" "$branch"; then
      health_print_finding "$repo_name" "$task_slug" "$status" \
        "local branch missing: $branch" "remove stale manifest or recreate branch"
      findings=$((findings + 1))
    elif [[ "$status" == "started" || "$status" == "pr_opened" ]]; then
      if health_branch_patch_equivalent "$worktree_path" "$base" "$branch"; then
        health_print_finding "$repo_name" "$task_slug" "$status" \
          "branch appears merged or patch-equivalent to $base" \
          "mark task complete and prune worktree after review"
        findings=$((findings + 1))
      fi
    fi

    if [[ "$status" == "started" || "$status" == "pr_opened" ]]; then
      health_changed_paths "$worktree_path" "$base" "$branch" \
        | sed '/^[[:space:]]*$/d' >"$active_paths/$scanned"
      if [[ -s "$active_paths/$scanned" ]]; then
        printf '%s\t%s\t%s\t%s\n' "$scanned" "$repo_name" "$task_slug" "$status" >>"$active_index"
      fi
    fi

    if [[ "$status" == "pr_opened" && "$gh_available" -eq 1 && -n "$repo_slug" ]]; then
      pr_state="$(health_pr_state "$repo_slug" "$branch")"
      if [[ -z "$pr_state" || "$pr_state" == "missing" ]]; then
        health_print_finding "$repo_name" "$task_slug" "$status" \
          "no GitHub PR found for $branch" "run just codex-pr or update manifest status"
        findings=$((findings + 1))
      else
        IFS=$'\t' read -r pr_status pr_merged pr_url <<<"$pr_state"
        if [[ "$pr_status" == "MERGED" || -n "$pr_merged" ]]; then
          health_print_finding "$repo_name" "$task_slug" "$status" \
            "GitHub PR is merged: $pr_url" "mark task complete and prune worktree after review"
          findings=$((findings + 1))
        elif [[ "$pr_status" == "CLOSED" ]]; then
          health_print_finding "$repo_name" "$task_slug" "$status" \
            "GitHub PR is closed: $pr_url" "inspect branch and update manifest status"
          findings=$((findings + 1))
        fi
      fi
    fi
  done
  shopt -u nullglob

  if [[ -s "$active_index" ]]; then
    while IFS=$'\t' read -r left_id left_repo left_task left_status; do
      while IFS=$'\t' read -r right_id right_repo right_task right_status; do
        [[ "$left_id" -lt "$right_id" ]] || continue
        [[ "$left_repo" == "$right_repo" ]] || continue
        overlap_file="$tmpdir/overlap-$left_id-$right_id"
        comm -12 <(sort -u "$active_paths/$left_id") <(sort -u "$active_paths/$right_id") >"$overlap_file"
        [[ -s "$overlap_file" ]] || continue
        overlap="$(health_compact_path_list "$overlap_file")"
        health_print_finding "$left_repo" "$left_task,$right_task" "$left_status/$right_status" \
          "active tasks overlap paths: $overlap" "coordinate branches before continuing"
        findings=$((findings + 1))
      done <"$active_index"
    done <"$active_index"
  fi

  echo
  echo "summary: scanned=$scanned findings=$findings"
}

cmd="${1:-}"
[[ -n "$cmd" ]] || {
  usage
  exit 1
}
shift

case "$cmd" in
  start) start_cmd "$@" ;;
  status) status_cmd "$@" ;;
  pr) pr_cmd "$@" ;;
  health) health_cmd "$@" ;;
  *)
    usage
    exit 1
    ;;
esac

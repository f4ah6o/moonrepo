set shell := ["bash", "-cu"]

REPO_LIST := "repository.ini"
REPOS_DIR := "repos"

# Initialize repository.ini from GitHub repository topics
# Example: just init f4ah6o --topics moonbit rust
init owner *args:
  just moonbit-skills
  @bash -ceu 'set -euo pipefail; \
    owner="$1"; \
    shift; \
    topics=""; \
    saw_topics=0; \
    while (($# > 0)); do \
      case "$1" in \
        --topics) \
          saw_topics=1; \
          shift; \
          while (($# > 0)); do \
            case "$1" in \
              --*) break ;; \
              *) topics="$topics $1"; shift ;; \
            esac; \
          done; \
          ;; \
        --*) \
          echo "unknown option: $1" >&2; \
          exit 1; \
          ;; \
        *) \
          echo "unexpected argument: $1 (use --topics <topic...>)" >&2; \
          exit 1; \
          ;; \
      esac; \
    done; \
    if [[ "$saw_topics" -eq 0 ]]; then \
      topics="moonbit rust"; \
    fi; \
    topics="$(printf "%s\n" $topics | tr "[:upper:]" "[:lower:]" | awk "NF" | sort -u | tr "\n" " " | sed -e "s/[[:space:]]*$//")"; \
    if [[ -z "$topics" ]]; then \
      echo "--topics requires at least one topic" >&2; \
      exit 1; \
    fi; \
    tmp="$(mktemp)"; \
    gh repo list "$owner" --json name -L 1000 --jq ".[] | .name" | while IFS= read -r name; do \
      [[ -z "$name" ]] && continue; \
      if ! repo_topics="$(gh api "repos/$owner/$name/topics" -H "Accept: application/vnd.github+json" --jq ".names[]?" 2>/dev/null)"; then \
        echo "warn: cannot fetch topics for $owner/$name" >&2; \
        continue; \
      fi; \
      repo_topics="$(printf "%s\n" "$repo_topics" | tr "[:upper:]" "[:lower:]")"; \
      matched=0; \
      for wanted in $topics; do \
        if printf "%s\n" "$repo_topics" | grep -Fxq "$wanted"; then \
          matched=1; \
          break; \
        fi; \
      done; \
      if [[ "$matched" -eq 1 ]]; then \
        echo "$name"; \
      fi; \
    done | sort -u > "$tmp"; \
    { \
      echo "; <owner>/<repo> を1行ずつ書く（空行と ; 行は無視）"; \
      echo "; 生成コマンド: just init $owner --topics $topics"; \
      echo "; 初期生成時はすべてコメントアウトされるので、必要なものだけ有効化する"; \
      echo "; topic に一致した repo をコメントアウトで出力する"; \
      echo "; 例:"; \
      while IFS= read -r name; do \
        [[ -z "$name" ]] && continue; \
        echo "; $owner/$name"; \
      done < "$tmp"; \
    } > "{{REPO_LIST}}"; \
    rm -f "$tmp"; \
    echo "generated {{REPO_LIST}} from $owner (topics: $topics)"' -- "{{owner}}" {{args}}

# Clone repos from repository.ini into ./repos
clone:
  @bash -ceu 'set -euo pipefail; \
    mkdir -p "{{REPOS_DIR}}"; \
    if [[ ! -f "{{REPO_LIST}}" ]]; then echo "missing {{REPO_LIST}}"; exit 1; fi; \
    while IFS= read -r repo; do \
      [[ -z "$repo" || "$repo" =~ ^# || "$repo" =~ ^\; ]] && continue; \
      name="${repo##*/}"; \
      dest="{{REPOS_DIR}}/$name"; \
      if [[ -d "$dest/.git" ]]; then echo "skip (exists): $repo -> $dest"; continue; fi; \
      gh repo clone "$repo" "$dest"; \
    done < "{{REPO_LIST}}"'

cclone: clean clone
check-all: fmt check test

moonbit-skills:
  rm -rf .agents/skills/moonbit-agent-guide
  rm -rf .agents/skills/moonbit-refactoring
  gh repo clone moonbitlang/moonbit-agent-guide .agents/skills/moonbit
  mv .agents/skills/moonbit/moonbit-agent-guide .agents/skills/
  mv .agents/skills/moonbit/moonbit-refactoring .agents/skills/
  rm -rf .agents/skills/moonbit

clean:
  rm -rf repos
  mkdir -p repos

# Pull updates for already cloned repos
pull:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -d "$dir/.git" ]] || continue; \
      echo "pull: $dir"; \
      git -C "$dir" pull --ff-only; \
    done'

# Push current branch for all repos
push-all:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -d "$dir/.git" ]] || continue; \
      echo "push: $dir"; \
      git -C "$dir" push; \
    done'

# Set git author config for all repos under ./repos
config name email:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -d "$dir/.git" ]] || continue; \
      git -C "$dir" config user.name "{{name}}"; \
      git -C "$dir" config user.email "{{email}}"; \
      echo "configured: $dir"; \
    done'

# Add moonbit topic to repos discoverable by current .mbt naming rule
# Example: just topics-migrate-moonbit
# Example: just topics-migrate-moonbit --apply
topics-migrate-moonbit *args:
  @bash -ceu 'set -euo pipefail; \
    apply=0; \
    for arg in "$@"; do \
      case "$arg" in \
        --apply) apply=1 ;; \
        *) echo "unknown option: $arg" >&2; exit 1 ;; \
      esac; \
    done; \
    topic="moonbit"; \
    planned=0; \
    updated=0; \
    unchanged=0; \
    failed=0; \
    upsert_topic() { \
      local repo="$1"; \
      local existing; \
      local merged; \
      local t; \
      local cmd; \
      if ! existing="$(gh api "repos/$repo/topics" -H "Accept: application/vnd.github+json" --jq ".names[]?" 2>/dev/null)"; then \
        echo "failed: $repo (cannot fetch topics)" >&2; \
        failed=$((failed + 1)); \
        return; \
      fi; \
      existing="$(printf "%s\n" "$existing" | tr "[:upper:]" "[:lower:]" | awk "NF" | sort -u)"; \
      if printf "%s\n" "$existing" | grep -Fxq "$topic"; then \
        echo "unchanged: $repo"; \
        unchanged=$((unchanged + 1)); \
        return; \
      fi; \
      planned=$((planned + 1)); \
      if [[ "$apply" -eq 0 ]]; then \
        echo "would add topic \"$topic\": $repo"; \
        return; \
      fi; \
      merged="$( { printf "%s\n" "$existing"; printf "%s\n" "$topic"; } | awk "NF" | sort -u )"; \
      cmd=(gh api -X PUT "repos/$repo/topics" -H "Accept: application/vnd.github+json"); \
      while IFS= read -r t; do \
        [[ -z "$t" ]] && continue; \
        cmd+=(-f "names[]=$t"); \
      done <<< "$merged"; \
      if "${cmd[@]}" >/dev/null 2>&1; then \
        echo "updated: $repo"; \
        updated=$((updated + 1)); \
      else \
        echo "failed: $repo (cannot update topics)" >&2; \
        failed=$((failed + 1)); \
      fi; \
    }; \
    for owner in f4ah6o horideicom; do \
      while IFS= read -r name; do \
        [[ -z "$name" ]] && continue; \
        upsert_topic "$owner/$name"; \
      done < <(gh repo list "$owner" --json name -L 1000 --jq ".[] | select(.name | contains(\".mbt\")) | .name"); \
    done; \
    mode="dry-run"; \
    if [[ "$apply" -eq 1 ]]; then mode="apply"; fi; \
    echo "mode: $mode"; \
    echo "planned: $planned"; \
    echo "updated: $updated"; \
    echo "unchanged: $unchanged"; \
    echo "failed: $failed"; \
    [[ "$failed" -eq 0 ]]' -- {{args}}

# Add a topic to repos listed in repository.ini (active lines only)
# Example: just topics-add-from-ini rust
# Example: just topics-add-from-ini rust --apply
topics-add-from-ini topic *args:
  @bash -ceu 'set -euo pipefail; \
    topic="$1"; \
    shift; \
    apply=0; \
    for arg in "$@"; do \
      case "$arg" in \
        --apply) apply=1 ;; \
        *) echo "unknown option: $arg" >&2; exit 1 ;; \
      esac; \
    done; \
    topic="$(printf "%s" "$topic" | tr "[:upper:]" "[:lower:]")"; \
    if [[ -z "$topic" ]]; then \
      echo "topic must not be empty" >&2; \
      exit 1; \
    fi; \
    if [[ ! -f "{{REPO_LIST}}" ]]; then \
      echo "missing {{REPO_LIST}}" >&2; \
      exit 1; \
    fi; \
    planned=0; \
    updated=0; \
    unchanged=0; \
    failed=0; \
    upsert_topic() { \
      local repo="$1"; \
      local existing; \
      local merged; \
      local t; \
      local cmd; \
      if ! existing="$(gh api "repos/$repo/topics" -H "Accept: application/vnd.github+json" --jq ".names[]?" 2>/dev/null)"; then \
        echo "failed: $repo (cannot fetch topics)" >&2; \
        failed=$((failed + 1)); \
        return; \
      fi; \
      existing="$(printf "%s\n" "$existing" | tr "[:upper:]" "[:lower:]" | awk "NF" | sort -u)"; \
      if printf "%s\n" "$existing" | grep -Fxq "$topic"; then \
        echo "unchanged: $repo"; \
        unchanged=$((unchanged + 1)); \
        return; \
      fi; \
      planned=$((planned + 1)); \
      if [[ "$apply" -eq 0 ]]; then \
        echo "would add topic \"$topic\": $repo"; \
        return; \
      fi; \
      merged="$( { printf "%s\n" "$existing"; printf "%s\n" "$topic"; } | awk "NF" | sort -u )"; \
      cmd=(gh api -X PUT "repos/$repo/topics" -H "Accept: application/vnd.github+json"); \
      while IFS= read -r t; do \
        [[ -z "$t" ]] && continue; \
        cmd+=(-f "names[]=$t"); \
      done <<< "$merged"; \
      if "${cmd[@]}" >/dev/null 2>&1; then \
        echo "updated: $repo"; \
        updated=$((updated + 1)); \
      else \
        echo "failed: $repo (cannot update topics)" >&2; \
        failed=$((failed + 1)); \
      fi; \
    }; \
    while IFS= read -r raw || [[ -n "$raw" ]]; do \
      line="$(printf "%s" "$raw" | sed -e "s/^[[:space:]]*//" -e "s/[[:space:]]*$//")"; \
      [[ -z "$line" || "$line" =~ ^# || "$line" =~ ^\; ]] && continue; \
      if ! printf "%s\n" "$line" | grep -Eq "^[^/[:space:]]+/[^/[:space:]]+$"; then \
        echo "skip invalid line: $line" >&2; \
        failed=$((failed + 1)); \
        continue; \
      fi; \
      upsert_topic "$line"; \
    done < "{{REPO_LIST}}"; \
    mode="dry-run"; \
    if [[ "$apply" -eq 1 ]]; then mode="apply"; fi; \
    echo "mode: $mode"; \
    echo "planned: $planned"; \
    echo "updated: $updated"; \
    echo "unchanged: $unchanged"; \
    echo "failed: $failed"; \
    [[ "$failed" -eq 0 ]]' -- "{{topic}}" {{args}}

# Scan dependencies for all repos
# Example: just deps-scan-all --json
# Example: just deps-scan-all --ignore tmp --ignore vendor

deps-scan-all *args:
  moon-dst scan --root "{{REPOS_DIR}}" {{args}}

# Apply dependency updates for all repos
# Example: just deps-apply-all --dry-run
# Example: just deps-apply-all --no-justfile

deps-apply-all *args:
  moon-dst apply --root "{{REPOS_DIR}}" {{args}}

# Add justfile to all repos
# Example: just deps-just-all --mode skip

deps-just-all *args:
  moon-dst just --root "{{REPOS_DIR}}" {{args}}

# Scan dependencies for one repo under ./repos
# Example: just deps-scan moonbit-lang-core

deps-scan repo *args:
  moon-dst scan --root "{{REPOS_DIR}}/{{repo}}" {{args}}

# Apply dependency updates for one repo under ./repos
# Example: just deps-apply moonbit-lang-core --dry-run

deps-apply repo *args:
  moon-dst apply --root "{{REPOS_DIR}}/{{repo}}" {{args}}

# Add justfile to one repo under ./repos
# Example: just deps-just moonbit-lang-core --mode skip

deps-just repo *args:
  moon-dst just --root "{{REPOS_DIR}}/{{repo}}" {{args}}

# Run moon fmt/check/build/clean for all repos (turbo-like)
moon-fmt-all:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -f "$dir/moon.mod.json" ]] || continue; \
      echo "moon fmt: $dir"; \
      moon -C "$dir" fmt; \
    done'

moon-check-all:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -f "$dir/moon.mod.json" ]] || continue; \
      echo "moon check: $dir"; \
      moon -C "$dir" check; \
    done'

moon-build-all:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -f "$dir/moon.mod.json" ]] || continue; \
      echo "moon build: $dir"; \
      moon -C "$dir" build; \
    done'

moon-clean-all:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -f "$dir/moon.mod.json" ]] || continue; \
      echo "moon clean: $dir"; \
      moon -C "$dir" clean; \
    done'

# Run moon fmt/check/build/clean for a single repo under ./repos
moon-fmt repo:
  moon -C "{{REPOS_DIR}}/{{repo}}" fmt

moon-check repo:
  moon -C "{{REPOS_DIR}}/{{repo}}" check

moon-build repo:
  moon -C "{{REPOS_DIR}}/{{repo}}" build

moon-clean repo:
  moon -C "{{REPOS_DIR}}/{{repo}}" clean

# Run moon test for all repos (turbo-like)
moon-test-all:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -f "$dir/moon.mod.json" ]] || continue; \
      echo "moon test: $dir"; \
      moon -C "$dir" test; \
    done'

# skill
skills-init:
  skop add moonbit-agent-guide@f4ah6o/skills-bonsai --target codex
  skop add moonbit-refactoring@f4ah6o/skills-bonsai --target codex

# Run moon test for a single repo under ./repos
moon-test repo:
  moon -C "{{REPOS_DIR}}/{{repo}}" test

# Standard CI entrypoints for this repo
apply: deps-apply-all

fmt: moon-fmt-all

check: moon-check-all

test: moon-test-all

build:
  @echo "build: nothing to build for this repo"

# Show git status for all repos
status-all:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -d "$dir/.git" ]] || continue; \
      echo "status: $dir"; \
      git -C "$dir" status -sb; \
    done'

# Show latest GitHub Actions run result for all repos
gh-runs-last-all:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    printf "%-40s | %-24s | %-10s | %-10s | %s\n" "repo" "workflow" "status" "conclusion" "url"; \
    printf "%-40s-+-%-24s-+-%-10s-+-%-10s-+-%s\n" "----------------------------------------" "------------------------" "----------" "----------" "------------------------------"; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -d "$dir/.git" ]] || continue; \
      remote_url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"; \
      if [[ -z "$remote_url" ]]; then \
        printf "%-40s | %-24s | %-10s | %-10s | %s\n" "$(basename "$dir")" "-" "error" "-" "missing origin"; \
        continue; \
      fi; \
      repo="${remote_url#git@github.com:}"; \
      repo="${repo#https://github.com/}"; \
      repo="${repo#http://github.com/}"; \
      repo="${repo%.git}"; \
      if ! json="$(gh run list -R "$repo" -L 1 --json workflowName,status,conclusion,url 2>/dev/null)"; then \
        printf "%-40s | %-24s | %-10s | %-10s | %s\n" "$repo" "-" "error" "-" "gh run list failed"; \
        continue; \
      fi; \
      line="$(jq -r '\''if length == 0 then "-\tno-run\t-\t-" else .[0] | [(.workflowName // "-"), (.status // "-"), (.conclusion // "-"), (.url // "-")] | @tsv end'\'' <<< "$json")"; \
      IFS=$'\''\t'\'' read -r workflow status conclusion url <<< "$line"; \
      printf "%-40s | %-24s | %-10s | %-10s | %s\n" "$repo" "$workflow" "$status" "$conclusion" "$url"; \
    done'

# Re-run latest failed GitHub Actions run for all repos
gh-runs-rerun-failed-all:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -d "$dir/.git" ]] || continue; \
      remote_url="$(git -C "$dir" remote get-url origin 2>/dev/null || true)"; \
      [[ -n "$remote_url" ]] || continue; \
      repo="${remote_url#git@github.com:}"; \
      repo="${repo#https://github.com/}"; \
      repo="${repo#http://github.com/}"; \
      repo="${repo%.git}"; \
      if ! json="$(gh run list -R "$repo" -L 1 --json databaseId,conclusion,workflowName,url 2>/dev/null)"; then \
        echo "skip: $repo (gh run list failed)"; \
        continue; \
      fi; \
      line="$(jq -r '\''if length == 0 then "" else .[0] | [(.databaseId|tostring), (.conclusion // "-"), (.workflowName // "-"), (.url // "-")] | @tsv end'\'' <<< "$json")"; \
      [[ -n "$line" ]] || continue; \
      IFS=$'\''\t'\'' read -r run_id conclusion workflow url <<< "$line"; \
      if [[ "$conclusion" != "failure" ]]; then \
        continue; \
      fi; \
      echo "rerun: $repo | $workflow | $run_id"; \
      if gh run rerun "$run_id" -R "$repo" >/dev/null 2>&1; then \
        echo "ok: $repo | $url"; \
      else \
        echo "failed: $repo | $run_id"; \
      fi; \
    done'

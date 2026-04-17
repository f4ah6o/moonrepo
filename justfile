set shell := ["bash", "-cu"]

REPO_LIST := "repository.ini"
REPOS_DIR := "repos"
REPO_SCOPE := "active"
FORCE := "0"

# Initialize repository.ini from GitHub repository topics
# Example: just init f4ah6o --topics moonbit rust
init owner *args:
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
    while IFS=$'\''\t'\'' read -r repo name dest; do \
      if [[ -d "$dest/.git" ]]; then echo "skip (exists): $repo -> $dest"; continue; fi; \
      gh repo clone "$repo" "$dest"; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" bash scripts/repo-targets.sh list active)'

cclone: clean clone
check-all: fmt check test

moonbit-skills:
  @echo "deprecated: use just skills-init"

clean:
  @bash -ceu 'set -euo pipefail; \
    if [[ "{{FORCE}}" != "1" ]]; then \
      echo "refusing to remove {{REPOS_DIR}} without FORCE=1"; \
      if [[ -d "{{REPOS_DIR}}" ]]; then \
        find "{{REPOS_DIR}}" -mindepth 1 -maxdepth 1 -type d | sort || true; \
      fi; \
      exit 1; \
    fi; \
    rm -rf "{{REPOS_DIR}}"; \
    mkdir -p "{{REPOS_DIR}}"'

doctor:
  @bash -ceu 'set -euo pipefail; \
    missing=0; \
    for cmd in gh just moon moon-dst jq; do \
      if command -v "$cmd" >/dev/null 2>&1; then \
        echo "ok command: $cmd"; \
      else \
        echo "missing command: $cmd" >&2; \
        missing=$((missing + 1)); \
      fi; \
    done; \
    if REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" bash scripts/repo-targets.sh validate; then \
      echo "ok repository.ini"; \
    else \
      missing=$((missing + 1)); \
    fi; \
    active_missing=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ -d "$path/.git" ]]; then \
        echo "ok active clone: $repo"; \
      else \
        echo "missing active clone: $repo -> $path" >&2; \
        active_missing=$((active_missing + 1)); \
      fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" bash scripts/repo-targets.sh list active); \
    extra_cloned=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      [[ -n "$repo" ]] || continue; \
      echo "extra cloned repo: $repo -> $path"; \
      extra_cloned=$((extra_cloned + 1)); \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" bash scripts/repo-targets.sh extra-cloned); \
    for skill in .agents/skills/moonbit-agent-guide/SKILL.md .agents/skills/moonbit-refactoring/SKILL.md; do \
      if [[ -f "$skill" ]]; then \
        echo "ok skill: $skill"; \
      else \
        echo "missing skill: $skill" >&2; \
        missing=$((missing + 1)); \
      fi; \
    done; \
    echo "summary: missing=$missing active_missing=$active_missing extra_cloned=$extra_cloned"; \
    [[ "$missing" -eq 0 && "$active_missing" -eq 0 ]]'

repos-prune *args:
  @bash -ceu 'set -euo pipefail; \
    apply=0; \
    source scripts/repo-lib.sh; \
    for arg in "$@"; do \
      case "$arg" in \
        --apply) apply=1 ;; \
        *) echo "unknown option: $arg" >&2; exit 1 ;; \
      esac; \
    done; \
    count=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      [[ -n "$repo" ]] || continue; \
      count=$((count + 1)); \
      dirty=0; \
      ahead=0; \
      if [[ -d "$path/.git" ]]; then \
        if repo_is_dirty "$path"; then dirty=1; fi; \
        if [[ "$(repo_ahead_count "$path")" != "0" ]]; then ahead=1; fi; \
      fi; \
      echo "prune candidate: $repo -> $path (dirty=$dirty ahead=$ahead)"; \
      if [[ "$apply" -eq 1 ]]; then \
        if [[ "$dirty" -eq 1 || "$ahead" -eq 1 ]] && [[ "{{FORCE}}" != "1" ]]; then \
          echo "skip protected prune: $repo"; \
          continue; \
        fi; \
        rm -rf "$path"; \
        echo "pruned: $repo"; \
      fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" bash scripts/repo-targets.sh extra-cloned); \
    mode="dry-run"; \
    if [[ "$apply" -eq 1 ]]; then mode="apply"; fi; \
    echo "mode: $mode"; \
    echo "planned: $count"' -- {{args}}

# Pull updates for already cloned repos
pull:
  @bash -ceu 'set -euo pipefail; \
    source scripts/repo-lib.sh; \
    ok=0; skipped_dirty=0; missing=0; failed=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if repo_is_dirty "$path"; then \
        echo "skip dirty: $repo"; \
        skipped_dirty=$((skipped_dirty + 1)); \
        continue; \
      fi; \
      echo "pull: $repo"; \
      if git -C "$path" pull --ff-only; then \
        ok=$((ok + 1)); \
      else \
        failed=$((failed + 1)); \
      fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: ok=$ok skipped_dirty=$skipped_dirty missing=$missing failed=$failed"; \
    [[ "$skipped_dirty" -eq 0 && "$missing" -eq 0 && "$failed" -eq 0 ]]'

# Push current branch for all repos
push-all:
  @bash -ceu 'set -euo pipefail; \
    ok=0; missing=0; failed=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      echo "push: $repo"; \
      if git -C "$path" push; then \
        ok=$((ok + 1)); \
      else \
        failed=$((failed + 1)); \
      fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: ok=$ok missing=$missing failed=$failed"; \
    [[ "$missing" -eq 0 && "$failed" -eq 0 ]]'

# Set git author config for all repos under ./repos
config name email:
  @bash -ceu 'set -euo pipefail; \
    ok=0; missing=0; \
    while IFS=$'\''\t'\'' read -r repo target_name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      git -C "$path" config user.name "{{name}}"; \
      git -C "$path" config user.email "{{email}}"; \
      echo "configured: $repo"; \
      ok=$((ok + 1)); \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: ok=$ok missing=$missing"; \
    [[ "$missing" -eq 0 ]]'

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
  @bash -ceu 'set -euo pipefail; \
    source scripts/repo-lib.sh; \
    missing=0; \
    cmd=(moon-dst scan --root "{{REPOS_DIR}}"); \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
      fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    if [[ "{{REPO_SCOPE}}" == "active" ]]; then \
      while IFS=$'\''\t'\'' read -r repo name path; do \
        [[ -n "$name" ]] || continue; \
        cmd+=(--ignore "$name"); \
      done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" bash scripts/repo-targets.sh extra-cloned); \
    fi; \
    if (($# > 0)); then cmd+=("$@"); fi; \
    "${cmd[@]}"; \
    [[ "$missing" -eq 0 ]]' -- {{args}}

# Apply dependency updates for all repos
# Example: just deps-apply-all --dry-run
# Example: just deps-apply-all --no-justfile

deps-apply-all *args:
  @bash -ceu 'set -euo pipefail; \
    source scripts/repo-lib.sh; \
    missing=0; skipped_dirty=0; \
    cmd=(moon-dst apply --root "{{REPOS_DIR}}"); \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if repo_is_dirty "$path"; then \
        echo "skip dirty: $repo"; \
        cmd+=(--ignore "$name"); \
        skipped_dirty=$((skipped_dirty + 1)); \
      fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    if [[ "{{REPO_SCOPE}}" == "active" ]]; then \
      while IFS=$'\''\t'\'' read -r repo name path; do \
        [[ -n "$name" ]] || continue; \
        cmd+=(--ignore "$name"); \
      done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" bash scripts/repo-targets.sh extra-cloned); \
    fi; \
    if (($# > 0)); then cmd+=("$@"); fi; \
    "${cmd[@]}"; \
    echo "summary: skipped_dirty=$skipped_dirty missing=$missing"; \
    [[ "$skipped_dirty" -eq 0 && "$missing" -eq 0 ]]' -- {{args}}

# Add justfile to all repos
# Example: just deps-just-all --mode skip

deps-just-all *args:
  @bash -ceu 'set -euo pipefail; \
    source scripts/repo-lib.sh; \
    missing=0; skipped_dirty=0; \
    cmd=(moon-dst just --root "{{REPOS_DIR}}"); \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if repo_is_dirty "$path"; then \
        echo "skip dirty: $repo"; \
        cmd+=(--ignore "$name"); \
        skipped_dirty=$((skipped_dirty + 1)); \
      fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    if [[ "{{REPO_SCOPE}}" == "active" ]]; then \
      while IFS=$'\''\t'\'' read -r repo name path; do \
        [[ -n "$name" ]] || continue; \
        cmd+=(--ignore "$name"); \
      done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" bash scripts/repo-targets.sh extra-cloned); \
    fi; \
    if (($# > 0)); then cmd+=("$@"); fi; \
    "${cmd[@]}"; \
    echo "summary: skipped_dirty=$skipped_dirty missing=$missing"; \
    [[ "$skipped_dirty" -eq 0 && "$missing" -eq 0 ]]' -- {{args}}

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
    source scripts/repo-lib.sh; \
    ok=0; missing=0; skipped_not_moon=0; failed=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if ! repo_is_moon "$path"; then \
        echo "skip not moon: $repo"; \
        skipped_not_moon=$((skipped_not_moon + 1)); \
        continue; \
      fi; \
      echo "moon fmt: $repo"; \
      if moon -C "$path" fmt; then ok=$((ok + 1)); else failed=$((failed + 1)); fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: ok=$ok skipped_not_moon=$skipped_not_moon missing=$missing failed=$failed"; \
    [[ "$missing" -eq 0 && "$failed" -eq 0 ]]'

moon-check-all:
  @bash -ceu 'set -euo pipefail; \
    source scripts/repo-lib.sh; \
    ok=0; missing=0; skipped_not_moon=0; failed=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if ! repo_is_moon "$path"; then \
        echo "skip not moon: $repo"; \
        skipped_not_moon=$((skipped_not_moon + 1)); \
        continue; \
      fi; \
      echo "moon check: $repo"; \
      if moon -C "$path" check; then ok=$((ok + 1)); else failed=$((failed + 1)); fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: ok=$ok skipped_not_moon=$skipped_not_moon missing=$missing failed=$failed"; \
    [[ "$missing" -eq 0 && "$failed" -eq 0 ]]'

moon-build-all:
  @bash -ceu 'set -euo pipefail; \
    source scripts/repo-lib.sh; \
    ok=0; missing=0; skipped_not_moon=0; failed=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if ! repo_is_moon "$path"; then \
        echo "skip not moon: $repo"; \
        skipped_not_moon=$((skipped_not_moon + 1)); \
        continue; \
      fi; \
      echo "moon build: $repo"; \
      if moon -C "$path" build; then ok=$((ok + 1)); else failed=$((failed + 1)); fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: ok=$ok skipped_not_moon=$skipped_not_moon missing=$missing failed=$failed"; \
    [[ "$missing" -eq 0 && "$failed" -eq 0 ]]'

moon-clean-all:
  @bash -ceu 'set -euo pipefail; \
    source scripts/repo-lib.sh; \
    ok=0; missing=0; skipped_not_moon=0; failed=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if ! repo_is_moon "$path"; then \
        echo "skip not moon: $repo"; \
        skipped_not_moon=$((skipped_not_moon + 1)); \
        continue; \
      fi; \
      echo "moon clean: $repo"; \
      if moon -C "$path" clean; then ok=$((ok + 1)); else failed=$((failed + 1)); fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: ok=$ok skipped_not_moon=$skipped_not_moon missing=$missing failed=$failed"; \
    [[ "$missing" -eq 0 && "$failed" -eq 0 ]]'

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
    source scripts/repo-lib.sh; \
    ok=0; missing=0; skipped_not_moon=0; failed=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if ! repo_is_moon "$path"; then \
        echo "skip not moon: $repo"; \
        skipped_not_moon=$((skipped_not_moon + 1)); \
        continue; \
      fi; \
      echo "moon test: $repo"; \
      if moon -C "$path" test; then ok=$((ok + 1)); else failed=$((failed + 1)); fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: ok=$ok skipped_not_moon=$skipped_not_moon missing=$missing failed=$failed"; \
    [[ "$missing" -eq 0 && "$failed" -eq 0 ]]'

# Bump the moonbit toolchain version across all f4ah6o repos with the
# "moonbit" GitHub topic. Touches .tool-versions and the install line in
# .github/workflows/*.yml. Does NOT touch moon.mod.json deps — use
# `just deps-apply-all` for that.
# Example: just moonbit-bump 0.1.20260215
# Example: just moonbit-bump 0.1.20260215 --apply
moonbit-bump version *args:
  @bash -ceu 'set -euo pipefail; \
    apply=0; \
    for arg in "$@"; do \
      case "$arg" in \
        --apply) apply=1 ;; \
        *) echo "unknown option: $arg" >&2; exit 1 ;; \
      esac; \
    done; \
    REPOS_DIR="{{REPOS_DIR}}" APPLY="$apply" VERSION="{{version}}" \
      bash scripts/moonbit-bump.sh' -- {{args}}

# Show the current moonbit toolchain version per target repo (read-only).
moonbit-bump-scan:
  @REPOS_DIR="{{REPOS_DIR}}" bash scripts/moonbit-bump.sh --scan-only

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
    missing=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      echo "status: $repo"; \
      git -C "$path" status -sb; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: missing=$missing"'

# Show latest GitHub Actions run result for all repos
gh-runs-last-all:
  @bash -ceu 'set -euo pipefail; \
    source scripts/repo-lib.sh; \
    missing=0; failed=0; \
    printf "%-40s | %-24s | %-10s | %-10s | %s\n" "repo" "workflow" "status" "conclusion" "url"; \
    printf "%-40s-+-%-24s-+-%-10s-+-%-10s-+-%s\n" "----------------------------------------" "------------------------" "----------" "----------" "------------------------------"; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        printf "%-40s | %-24s | %-10s | %-10s | %s\n" "$repo" "-" "missing" "-" "$path"; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if ! repo="$(repo_slug_from_path "$path")"; then \
        printf "%-40s | %-24s | %-10s | %-10s | %s\n" "$name" "-" "error" "-" "missing origin"; \
        failed=$((failed + 1)); \
        continue; \
      fi; \
      if ! json="$(gh run list -R "$repo" -L 1 --json workflowName,status,conclusion,url 2>/dev/null)"; then \
        printf "%-40s | %-24s | %-10s | %-10s | %s\n" "$repo" "-" "error" "-" "gh run list failed"; \
        failed=$((failed + 1)); \
        continue; \
      fi; \
      line="$(jq -r '\''if length == 0 then "-\tno-run\t-\t-" else .[0] | [(.workflowName // "-"), (.status // "-"), (.conclusion // "-"), (.url // "-")] | @tsv end'\'' <<< "$json")"; \
      IFS=$'\''\t'\'' read -r workflow status conclusion url <<< "$line"; \
      printf "%-40s | %-24s | %-10s | %-10s | %s\n" "$repo" "$workflow" "$status" "$conclusion" "$url"; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    echo "summary: missing=$missing failed=$failed"'

# Re-run latest failed GitHub Actions run for all repos
gh-runs-rerun-failed-all *args:
  @bash -ceu 'set -euo pipefail; \
    source scripts/repo-lib.sh; \
    apply=0; \
    for arg in "$@"; do \
      case "$arg" in \
        --apply) apply=1 ;; \
        *) echo "unknown option: $arg" >&2; exit 1 ;; \
      esac; \
    done; \
    rerun=0; failed=0; missing=0; \
    while IFS=$'\''\t'\'' read -r repo name path; do \
      if [[ ! -d "$path/.git" ]]; then \
        echo "missing: $repo -> $path" >&2; \
        missing=$((missing + 1)); \
        continue; \
      fi; \
      if ! repo="$(repo_slug_from_path "$path")"; then \
        echo "skip: $name (missing origin)"; \
        failed=$((failed + 1)); \
        continue; \
      fi; \
      if ! json="$(gh run list -R "$repo" -L 1 --json databaseId,conclusion,workflowName,url 2>/dev/null)"; then \
        echo "skip: $repo (gh run list failed)"; \
        failed=$((failed + 1)); \
        continue; \
      fi; \
      line="$(jq -r '\''if length == 0 then "" else .[0] | [(.databaseId|tostring), (.conclusion // "-"), (.workflowName // "-"), (.url // "-")] | @tsv end'\'' <<< "$json")"; \
      [[ -n "$line" ]] || continue; \
      IFS=$'\''\t'\'' read -r run_id conclusion workflow url <<< "$line"; \
      if [[ "$conclusion" != "failure" ]]; then \
        continue; \
      fi; \
      if [[ "$apply" -eq 0 ]]; then \
        echo "would rerun: $repo | $workflow | $run_id | $url"; \
        rerun=$((rerun + 1)); \
        continue; \
      fi; \
      echo "rerun: $repo | $workflow | $run_id"; \
      if gh run rerun "$run_id" -R "$repo" >/dev/null 2>&1; then \
        echo "ok: $repo | $url"; \
        rerun=$((rerun + 1)); \
      else \
        echo "failed: $repo | $run_id"; \
        failed=$((failed + 1)); \
      fi; \
    done < <(REPO_LIST="{{REPO_LIST}}" REPOS_DIR="{{REPOS_DIR}}" REPO_SCOPE="{{REPO_SCOPE}}" bash scripts/repo-targets.sh list); \
    mode="dry-run"; \
    if [[ "$apply" -eq 1 ]]; then mode="apply"; fi; \
    echo "summary: mode=$mode rerun=$rerun missing=$missing failed=$failed"; \
    [[ "$missing" -eq 0 && "$failed" -eq 0 ]]' -- {{args}}

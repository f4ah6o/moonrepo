set shell := ["bash", "-cu"]

REPO_LIST := "repository.ini"
REPOS_DIR := "repos"

# Initialize repository.ini from gh repo list
# Example: just init moonbitlang
init owner:
  @bash -ceu 'set -euo pipefail; \
    tmp="$(mktemp)"; \
    gh repo list "{{owner}}" --json name -L 1000 --jq ".[] | select(.name | contains(\".mbt\")) | .name" > "$tmp"; \
    { \
      echo "# <owner>/<repo> を1行ずつ書く（空行と # 行は無視）"; \
      echo "# 生成コマンド: just init {{owner}}"; \
      echo "# 初期生成時はすべてコメントアウトされるので、必要なものだけ有効化する"; \
      echo "# 例:"; \
      echo "# {{owner}}/core"; \
      while IFS= read -r name; do \
        [[ -z "$name" ]] && continue; \
        echo "# {{owner}}/$name"; \
      done < "$tmp"; \
    } > "{{REPO_LIST}}"; \
    rm -f "$tmp"; \
    echo "generated {{REPO_LIST}} from {{owner}}"'

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

# Clone missing repos, then pull updates
sync: clone pull

# Set git author config for all repos under ./repos
config-all name email:
  @bash -ceu 'set -euo pipefail; \
    if [[ ! -d "{{REPOS_DIR}}" ]]; then echo "missing {{REPOS_DIR}}"; exit 1; fi; \
    shopt -s nullglob; \
    for dir in "{{REPOS_DIR}}"/*; do \
      [[ -d "$dir/.git" ]] || continue; \
      git -C "$dir" config user.name "{{name}}"; \
      git -C "$dir" config user.email "{{email}}"; \
      echo "configured: $dir"; \
    done'

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
apply:
  just deps-apply-all

check:
  just moon-check-all

test:
  just moon-test-all

build:
  @echo "build: nothing to build for this repo"

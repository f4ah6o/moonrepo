#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SKILL_DIR}/../../.." && pwd)"

# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

usage() {
  cat <<'USAGE'
Usage:
  enable_tornado_repo.sh <repo_name> [--force] [--dry-run] [--review-model <model>] [--max-review-cycles <n>]

Examples:
  enable_tornado_repo.sh FWD.mbt
  enable_tornado_repo.sh FWD.mbt --dry-run
  enable_tornado_repo.sh FWD.mbt --force --review-model gpt-5.3-codex --max-review-cycles 3
USAGE
}

extract_section() {
  local snippet_file="$1"
  local section="$2"
  awk -v begin="# BEGIN ${section}" -v end="# END ${section}" '
    $0 == begin { in_section = 1; next }
    $0 == end { in_section = 0; exit }
    in_section == 1 { print }
  ' "$snippet_file"
}

render_tornado_json() {
  local template_file="$1"
  local review_model="$2"
  local max_review_cycles="$3"
  awk -v model="$review_model" -v cycles="$max_review_cycles" '
    {
      gsub(/__REVIEW_MODEL__/, model);
      gsub(/__MAX_REVIEW_CYCLES__/, cycles);
      print;
    }
  ' "$template_file"
}

repo_name=""
force=0
dry_run=0
review_model="gpt-5.3-codex"
max_review_cycles="3"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --review-model)
      shift
      [[ $# -gt 0 ]] || die "Missing value for --review-model"
      review_model="$1"
      shift
      ;;
    --max-review-cycles)
      shift
      [[ $# -gt 0 ]] || die "Missing value for --max-review-cycles"
      max_review_cycles="$1"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown option: $1"
      ;;
    *)
      if [[ -n "$repo_name" ]]; then
        die "Multiple repo names provided. Use exactly one."
      fi
      repo_name="$1"
      shift
      ;;
  esac
done

[[ -n "$repo_name" ]] || {
  usage
  die "repo_name is required"
}

[[ "$repo_name" != */* ]] || die "repo_name must be a bare repo name (example: FWD.mbt)"
[[ -n "$review_model" ]] || die "--review-model must not be empty"
is_positive_integer "$max_review_cycles" || die "--max-review-cycles must be a positive integer"

target_dir="${REPO_ROOT}/target-repos/${repo_name}.git/.wt/main"
justfile="${target_dir}/justfile"
tornado_json="${target_dir}/tornado.json"
config_template="${SKILL_DIR}/references/config-template.json"
just_snippet="${SKILL_DIR}/references/just-snippet.just"

[[ -d "$target_dir" ]] || die "Target repository not found: ${target_dir}"
[[ -f "$justfile" ]] || die "justfile not found: ${justfile}"
[[ -f "$config_template" ]] || die "Missing config template: ${config_template}"
[[ -f "$just_snippet" ]] || die "Missing just snippet: ${just_snippet}"

info "Target repo: ${target_dir}"
info "review model: ${review_model}"
info "max review cycles: ${max_review_cycles}"

changed_json=0
if [[ -f "$tornado_json" ]]; then
  if [[ "$force" -eq 1 ]]; then
    rendered_json="$(render_tornado_json "$config_template" "$review_model" "$max_review_cycles")"
    if [[ "$dry_run" -eq 1 ]]; then
      info "DRY-RUN: would overwrite ${tornado_json}"
    else
      printf '%s\n' "$rendered_json" > "$tornado_json"
      info "Overwrote ${tornado_json}"
    fi
    changed_json=1
  else
    warn "Skip existing ${tornado_json} (use --force to overwrite)"
  fi
else
  rendered_json="$(render_tornado_json "$config_template" "$review_model" "$max_review_cycles")"
  if [[ "$dry_run" -eq 1 ]]; then
    info "DRY-RUN: would create ${tornado_json}"
  else
    printf '%s\n' "$rendered_json" > "$tornado_json"
    info "Created ${tornado_json}"
  fi
  changed_json=1
fi

has_tornado_recipe=0
has_tornado_validate_recipe=0
if rg -n '^tornado(\s|:)' "$justfile" >/dev/null 2>&1; then
  has_tornado_recipe=1
fi
if rg -n '^tornado-validate:' "$justfile" >/dev/null 2>&1; then
  has_tornado_validate_recipe=1
fi

append_block=""
if [[ "$has_tornado_recipe" -eq 0 ]]; then
  tornado_recipe="$(extract_section "$just_snippet" "tornado-recipe")"
  [[ -n "$tornado_recipe" ]] || die "Missing snippet section: tornado-recipe"
  append_block="${tornado_recipe}"
else
  warn "Skip existing tornado recipe in ${justfile}"
fi

if [[ "$has_tornado_validate_recipe" -eq 0 ]]; then
  tornado_validate_recipe="$(extract_section "$just_snippet" "tornado-validate-recipe")"
  [[ -n "$tornado_validate_recipe" ]] || die "Missing snippet section: tornado-validate-recipe"
  if [[ -n "$append_block" ]]; then
    append_block="${append_block}"$'\n\n'"${tornado_validate_recipe}"
  else
    append_block="${tornado_validate_recipe}"
  fi
else
  warn "Skip existing tornado-validate recipe in ${justfile}"
fi

changed_justfile=0
if [[ -n "$append_block" ]]; then
  if [[ "$dry_run" -eq 1 ]]; then
    info "DRY-RUN: would append recipes to ${justfile}:"
    printf '\n%s\n' "$append_block"
  else
    printf '\n%s\n' "$append_block" >> "$justfile"
    info "Appended missing tornado recipes to ${justfile}"
  fi
  changed_justfile=1
fi

if [[ "$dry_run" -eq 1 ]]; then
  info "Dry-run complete."
else
  if [[ "$changed_json" -eq 0 && "$changed_justfile" -eq 0 ]]; then
    info "No file changes were needed."
  else
    info "Apply complete."
  fi
fi

info "Validation command:"
info "  (cd ${target_dir} && just tornado-validate)"

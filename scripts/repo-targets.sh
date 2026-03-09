#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./repo-lib.sh
source "$script_dir/repo-lib.sh"

cmd="${1:-list}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$cmd" in
  list)
    if [[ $# -gt 0 ]]; then
      REPO_SCOPE="$1"
      shift
    fi
    [[ $# -eq 0 ]] || { echo "usage: repo-targets.sh list [active|cloned]" >&2; exit 1; }
    list_target_repo_entries
    ;;
  extra-cloned)
    [[ $# -eq 0 ]] || { echo "usage: repo-targets.sh extra-cloned" >&2; exit 1; }
    list_extra_cloned_repo_entries
    ;;
  validate)
    [[ $# -eq 0 ]] || { echo "usage: repo-targets.sh validate" >&2; exit 1; }
    validate_repo_list
    ;;
  *)
    echo "unknown command: $cmd" >&2
    exit 1
    ;;
esac

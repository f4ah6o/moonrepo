#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../../../.." && pwd)"
# shellcheck source=../../../../scripts/repo-lib.sh
source "$repo_root/scripts/repo-lib.sh"

usage() {
  cat <<'EOF' >&2
Usage:
  docs-workflow.sh <repo_name> <task-slug>

Example:
  bash .agents/skills/docs-humanizer/scripts/docs-workflow.sh mhx.mbt docs-pass
EOF
}

[[ $# -eq 2 ]] || {
  usage
  exit 1
}

repo_name="$1"
task_slug="$2"
manifest_path="$(codex_manifest_path "$repo_root/.codex/tasks" "$repo_name" "$task_slug")"

(
  cd "$repo_root"
  REPO_LIST="${REPO_LIST:-repository.ini}" REPOS_DIR="${REPOS_DIR:-repos}" \
    bash scripts/codex-task.sh start "$repo_name" "$task_slug"
)

[[ -f "$manifest_path" ]] || {
  echo "manifest not found after codex-start: $manifest_path" >&2
  exit 1
}

worktree_path="$(jq -r '.worktree' "$manifest_path")"

echo ""
echo "initial document audit:"
bash "$script_dir/audit-docs.sh" --path "$worktree_path" || true

echo ""
cat <<EOF
docs worker prompt:
  Use the docs-humanizer skill from the moonrepo workspace.
  Edit tracked documents under $worktree_path.
  Start with files flagged above, then review the remaining tracked documents.
  Apply the checklist in .agents/skills/docs-humanizer/references/anti-ai-checklist-ja.md.
  Re-run:
    bash .agents/skills/docs-humanizer/scripts/audit-docs.sh --path "$worktree_path"
  Keep going until remaining findings are intentional and the docs read like specific technical writing.
EOF

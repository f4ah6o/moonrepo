#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  audit-docs.sh <repo_name>
  audit-docs.sh --path <repo_or_worktree_path>

Examples:
  bash .agents/skills/docs-humanizer/scripts/audit-docs.sh mhx.mbt
  bash .agents/skills/docs-humanizer/scripts/audit-docs.sh --path target-repos/mhx.mbt.git/.wt/codex/docs-pass
EOF
}

die() {
  echo "$*" >&2
  exit 1
}

TARGET_LABEL=""
TARGET_PATH=""
REPOS_DIR="${REPOS_DIR:-repos}"

if [[ $# -eq 1 && "$1" != "--path" ]]; then
  TARGET_LABEL="$1"
  TARGET_PATH="$REPOS_DIR/$1"
elif [[ $# -eq 2 && "$1" == "--path" ]]; then
  TARGET_PATH="$2"
  TARGET_LABEL="$(basename "$TARGET_PATH")"
else
  usage >&2
  exit 1
fi

[[ -d "$TARGET_PATH" ]] || die "target path not found: $TARGET_PATH"
git -C "$TARGET_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "not a git worktree: $TARGET_PATH"

declare -a docs=()
while IFS= read -r -d '' rel; do
  case "$rel" in
    node_modules/*|dist/*|coverage/*|target/*|_build/*|.moon/*|.wrangler/*|vendor/*|artifacts/*|fixtures/docs-site/upstream-snapshot/artifacts/*)
      continue
      ;;
  esac
  case "$rel" in
    *.md|*.mdx|*.txt|*.rst|*.adoc)
      docs+=("$rel")
      ;;
  esac
done < <(git -C "$TARGET_PATH" ls-files -z)

printf 'repo:  %s\n' "$TARGET_LABEL"
printf 'path:  %s\n' "$TARGET_PATH"
printf 'docs:  %s tracked document(s)\n' "${#docs[@]}"

if [[ "${#docs[@]}" -eq 0 ]]; then
  exit 0
fi

findings=0
flagged_files=''
count_dash=0
count_inline_bullet_header=0
count_chatbot_residue=0
count_templated_open_close=0
count_over_hedging=0
count_vague_source=0
count_ai_vocab=0
count_significance=0
count_mechanical_bold=0
count_bold_overuse=0
count_transition_overuse=0

mark_flagged_file() {
  local rel="$1"
  if ! printf '%s\n' "$flagged_files" | grep -Fqx "$rel"; then
    flagged_files="${flagged_files}${rel}"$'\n'
  fi
}

increment_rule() {
  local rule="$1"
  case "$rule" in
    dash) count_dash=$((count_dash + 1)) ;;
    inline-bullet-header) count_inline_bullet_header=$((count_inline_bullet_header + 1)) ;;
    chatbot-residue) count_chatbot_residue=$((count_chatbot_residue + 1)) ;;
    templated-open-close) count_templated_open_close=$((count_templated_open_close + 1)) ;;
    over-hedging) count_over_hedging=$((count_over_hedging + 1)) ;;
    vague-source) count_vague_source=$((count_vague_source + 1)) ;;
    ai-vocab) count_ai_vocab=$((count_ai_vocab + 1)) ;;
    significance) count_significance=$((count_significance + 1)) ;;
    mechanical-bold) count_mechanical_bold=$((count_mechanical_bold + 1)) ;;
    bold-overuse) count_bold_overuse=$((count_bold_overuse + 1)) ;;
    transition-overuse) count_transition_overuse=$((count_transition_overuse + 1)) ;;
  esac
}

report_line_matches() {
  local rule="$1"
  local regex="$2"
  local file="$3"
  local rel="$4"
  local matches line

  matches="$(grep -nE "$regex" "$file" || true)"
  [[ -n "$matches" ]] || return 0

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    printf '[%s] %s:%s\n' "$rule" "$rel" "$line"
    findings=$((findings + 1))
    increment_rule "$rule"
    mark_flagged_file "$rel"
  done <<<"$matches"
}

report_file_hint() {
  local rule="$1"
  local rel="$2"
  local message="$3"

  printf '[%s] %s:%s\n' "$rule" "$rel" "$message"
  findings=$((findings + 1))
  increment_rule "$rule"
  mark_flagged_file "$rel"
}

for rel in "${docs[@]}"; do
  file="$TARGET_PATH/$rel"
  [[ -f "$file" ]] || continue

  report_line_matches "dash" '[—―]' "$file" "$rel"
  report_line_matches "inline-bullet-header" '^[[:space:]]*[-*][[:space:]]+(\*\*[^*]+\*\*|[^:：]{1,24})[:：][[:space:]]' "$file" "$rel"
  report_line_matches "chatbot-residue" 'もちろん|以下に|以下では|ご質問|ご安心ください|お手伝いします|まとめると' "$file" "$rel"
  report_line_matches "templated-open-close" 'ここでは.+(解説|紹介)します|本稿では.+(解説|紹介)します|今後の展開が注目されます|今後の動向が注目されます' "$file" "$rel"
  report_line_matches "over-hedging" '可能性があります|かもしれません|と思われます|と考えられます|といえるでしょう' "$file" "$rel"
  report_line_matches "vague-source" 'と言われています|とされています|とされます|一般に' "$file" "$rel"
  report_line_matches "ai-vocab" 'さらに|加えて|浮き彫り|示唆|位置づけ|役割を果た' "$file" "$rel"
  report_line_matches "significance" '重要性|画期的|革新的|非常に重要|大きな意味|大きな示唆' "$file" "$rel"
  report_line_matches "mechanical-bold" '\*\*[^*]{1,40}\*\*[:：]' "$file" "$rel"

  bold_pairs="$( { grep -o '\*\*' "$file" 2>/dev/null || true; } | wc -l | tr -d ' ' )"
  if [[ "$bold_pairs" -ge 12 ]]; then
    report_file_hint "bold-overuse" "$rel" "0:contains many bold markers ($bold_pairs)"
  fi

  transition_count="$( { grep -oE 'さらに|加えて' "$file" 2>/dev/null || true; } | wc -l | tr -d ' ' )"
  if [[ "$transition_count" -ge 3 ]]; then
    report_file_hint "transition-overuse" "$rel" "0:repeated transition words ($transition_count)"
  fi
done

echo ""
flagged_count="$(printf '%s\n' "$flagged_files" | awk 'NF {c++} END {print c+0}')"
printf 'summary: findings=%s flagged_files=%s\n' "$findings" "$flagged_count"
[[ "$count_ai_vocab" -gt 0 ]] && printf '  - ai-vocab: %s\n' "$count_ai_vocab"
[[ "$count_bold_overuse" -gt 0 ]] && printf '  - bold-overuse: %s\n' "$count_bold_overuse"
[[ "$count_chatbot_residue" -gt 0 ]] && printf '  - chatbot-residue: %s\n' "$count_chatbot_residue"
[[ "$count_dash" -gt 0 ]] && printf '  - dash: %s\n' "$count_dash"
[[ "$count_inline_bullet_header" -gt 0 ]] && printf '  - inline-bullet-header: %s\n' "$count_inline_bullet_header"
[[ "$count_mechanical_bold" -gt 0 ]] && printf '  - mechanical-bold: %s\n' "$count_mechanical_bold"
[[ "$count_over_hedging" -gt 0 ]] && printf '  - over-hedging: %s\n' "$count_over_hedging"
[[ "$count_significance" -gt 0 ]] && printf '  - significance: %s\n' "$count_significance"
[[ "$count_templated_open_close" -gt 0 ]] && printf '  - templated-open-close: %s\n' "$count_templated_open_close"
[[ "$count_transition_overuse" -gt 0 ]] && printf '  - transition-overuse: %s\n' "$count_transition_overuse"
[[ "$count_vague_source" -gt 0 ]] && printf '  - vague-source: %s\n' "$count_vague_source"

if [[ "$findings" -gt 0 ]]; then
  echo "note: this is a heuristic audit. Re-run after rewriting, then do a human editorial pass with references/anti-ai-checklist-ja.md."
fi

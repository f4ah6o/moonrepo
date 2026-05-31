#!/usr/bin/env bash
set -euo pipefail

REPO_LIST="${REPO_LIST:-repository.ini}"
REPOS_DIR="${REPOS_DIR:-target-repos}"
RALLY_AGENT_PARENT="${RALLY_AGENT_PARENT:-moonrepo}"
RALLY_TEAM_PREFIX="${RALLY_TEAM_PREFIX:-repo-group-}"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

normalize_group() {
  local raw="$1"
  local group

  group="$(printf '%s' "$raw" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's|[^a-z0-9._-]+|-|g; s|^[._-]+||; s|[._-]+$||; s|-+|-|g')"
  [[ -n "$group" ]] || return 1
  printf '%s\n' "$group"
}

normalize_slug() {
  normalize_group "$1"
}

rally_team_name() {
  local group="$1"
  printf '%s%s\n' "$RALLY_TEAM_PREFIX" "$group"
}

require_repo_list() {
  [[ -f "$REPO_LIST" ]] || { echo "missing $REPO_LIST" >&2; exit 1; }
}

list_group_entries() {
  require_repo_list
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
      if (line ~ /^\[[^]]+\]$/) {
        section = tolower(substr(line, 2, length(line) - 2))
        next
      }
      if (section != "rally.teams") {
        next
      }
      eq = index(line, "=")
      if (eq == 0) {
        printf "invalid rally team line: %s\n", line > "/dev/stderr"
        invalid = 1
        next
      }
      group = trim(substr(line, 1, eq - 1))
      members = trim(substr(line, eq + 1))
      if (group == "" || members == "") {
        printf "invalid rally team line: %s\n", line > "/dev/stderr"
        invalid = 1
        next
      }
      n = split(members, parts, ",")
      for (i = 1; i <= n; i++) {
        member = trim(parts[i])
        if (member != "") {
          printf "%s\t%s\n", group, member
        }
      }
    }
    END {
      if (invalid) {
        exit 1
      }
    }
  ' "$REPO_LIST"
}

list_groups() {
  list_group_entries | awk -F '\t' '!seen[$1]++ { print $1 }'
}

group_members() {
  local group
  group="$(normalize_group "$1")" || { echo "invalid group: $1" >&2; exit 1; }
  list_group_entries | awk -F '\t' -v group="$group" '$1 == group { print $2 }'
}

require_group() {
  local group="$1"
  local members

  members="$(group_members "$group")"
  if [[ -z "$members" ]]; then
    echo "unknown rally group: $group" >&2
    exit 1
  fi
  printf '%s\n' "$members"
}

require_ral_script() {
  local script="$1"
  local path="$HOME/.agents/skills/ral/scripts/$script"

  [[ -x "$path" ]] || { echo "missing ral wrapper; run: just rally-install" >&2; exit 1; }
  printf '%s\n' "$path"
}

repo_path_for_member() {
  local member="$1"
  local name="${member##*/}"

  printf '%s/%s.git/.wt/main\n' "$REPOS_DIR" "$name"
}

cmd_list() {
  local group members team

  while IFS= read -r group; do
    [[ -n "$group" ]] || continue
    team="$(rally_team_name "$group")"
    members="$(group_members "$group" | awk 'BEGIN { sep = "" } { printf "%s%s", sep, $0; sep = ", " } END { print "" }')"
    printf '%s\t%s\t%s\n' "$group" "$team" "$members"
  done < <(list_groups)
}

cmd_show() {
  local group team member path

  group="$(normalize_group "$1")" || { echo "invalid group: $1" >&2; exit 1; }
  team="$(rally_team_name "$group")"
  printf 'group: %s\n' "$group"
  printf 'team:  %s\n' "$team"
  printf 'members:\n'
  while IFS= read -r member; do
    [[ -n "$member" ]] || continue
    path="$(repo_path_for_member "$member")"
    printf '  - %s -> %s\n' "$member" "$path"
  done < <(require_group "$group")
}

cmd_validate() {
  local failed=0
  local group member path

  while IFS=$'\t' read -r group member; do
    [[ -n "$group" && -n "$member" ]] || continue
    path="$(repo_path_for_member "$member")"
    if [[ -e "$path/.git" ]]; then
      printf 'ok group member: %s/%s\n' "$group" "$member"
    else
      printf 'missing group member worktree: %s/%s -> %s\n' "$group" "$member" "$path" >&2
      failed=$((failed + 1))
    fi
  done < <(list_group_entries)
  [[ "$failed" -eq 0 ]]
}

cmd_join() {
  local group team join delivery member path

  group="$(normalize_group "$1")" || { echo "invalid group: $1" >&2; exit 1; }
  team="$(rally_team_name "$group")"
  join="$(require_ral_script join.sh)"
  delivery="$(require_ral_script delivery.sh)"

  "$join" "$team" "$RALLY_AGENT_PARENT" codex "$(pwd)"
  while IFS= read -r member; do
    [[ -n "$member" ]] || continue
    path="$(repo_path_for_member "$member")"
    "$join" "$team" "$member" codex "$path"
  done < <(require_group "$group")
  "$delivery" set turn codex "$(pwd)"
}

cmd_inbox() {
  local group agent team inbox

  group="$(normalize_group "$1")" || { echo "invalid group: $1" >&2; exit 1; }
  agent="$2"
  require_group "$group" >/dev/null
  team="$(rally_team_name "$group")"
  inbox="$(require_ral_script inbox.sh)"
  "$inbox" "$team" "$agent"
}

cmd_send() {
  local group from to message team send member

  group="$(normalize_group "$1")" || { echo "invalid group: $1" >&2; exit 1; }
  from="$2"
  to="$3"
  message="$4"
  team="$(rally_team_name "$group")"
  send="$(require_ral_script send.sh)"
  require_group "$group" >/dev/null

  if [[ "$to" == "all" ]]; then
    if [[ "$from" != "$RALLY_AGENT_PARENT" ]]; then
      "$send" "$team" "$from" "$RALLY_AGENT_PARENT" "$message"
    fi
    while IFS= read -r member; do
      [[ -n "$member" && "$member" != "$from" ]] || continue
      "$send" "$team" "$from" "$member" "$message"
    done < <(group_members "$group")
  else
    "$send" "$team" "$from" "$to" "$message"
  fi
}

write_changelog() {
  local group source_repo slug summary team date path members

  group="$1"
  source_repo="$2"
  slug="$3"
  summary="$4"
  team="$(rally_team_name "$group")"
  date="$(date +%Y-%m-%d)"
  path="docs/rally/$group/$date-$slug.md"
  members="$(group_members "$group" | sed 's/^/- /')"
  mkdir -p "$(dirname "$path")"
  cat >"$path" <<EOF
# $summary

- date: $date
- group: $group
- ral team: $team
- source repo: $source_repo

## Related repos

$members

## Summary

$summary

## Follow-up

- 
EOF
  printf '%s\n' "$path"
}

cmd_changelog() {
  local group source_repo slug summary path message send

  group="$(normalize_group "$1")" || { echo "invalid group: $1" >&2; exit 1; }
  source_repo="$2"
  slug="$(normalize_slug "$3")" || { echo "invalid slug: $3" >&2; exit 1; }
  summary="$4"
  require_group "$group" >/dev/null
  path="$(write_changelog "$group" "$source_repo" "$slug" "$summary")"
  printf 'created changelog: %s\n' "$path"

  message="[$group changelog] $source_repo: $summary ($path)"
  if send="$(require_ral_script send.sh 2>/dev/null)"; then
    cmd_send "$group" "$source_repo" all "$message"
  else
    echo "skip ral send: missing ral wrapper; run: just rally-install" >&2
  fi
}

usage() {
  cat <<'EOF'
usage: rally-groups.sh <command> [args]

commands:
  list
  show <group>
  validate
  join <group>
  inbox <group> <agent>
  send <group> <from> <to|all> <message>
  changelog <group> <source-repo> <slug> <summary>
EOF
}

cmd="${1:-}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$cmd" in
  list) [[ $# -eq 0 ]] || { usage >&2; exit 1; }; cmd_list ;;
  show) [[ $# -eq 1 ]] || { usage >&2; exit 1; }; cmd_show "$1" ;;
  validate) [[ $# -eq 0 ]] || { usage >&2; exit 1; }; cmd_validate ;;
  join) [[ $# -eq 1 ]] || { usage >&2; exit 1; }; cmd_join "$1" ;;
  inbox) [[ $# -eq 2 ]] || { usage >&2; exit 1; }; cmd_inbox "$1" "$2" ;;
  send) [[ $# -eq 4 ]] || { usage >&2; exit 1; }; cmd_send "$1" "$2" "$3" "$4" ;;
  changelog) [[ $# -eq 4 ]] || { usage >&2; exit 1; }; cmd_changelog "$1" "$2" "$3" "$4" ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 1 ;;
esac

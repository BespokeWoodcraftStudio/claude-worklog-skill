#!/usr/bin/env bash
#
# worklog.sh — append a structured entry to a project's work journal.
#
# The work journal (docs/worklog/) is the chronological, cross-linked record of WHAT
# was done, WHY, and HOW — the "lab notebook" that makes a project fast to understand.
# One file per day (docs/worklog/YYYY-MM-DD.md); each entry gets a stable id
# WL-YYYY-MM-DD-NNN so it can be linked from other entries and commits.
#
# Repo-agnostic. Target dir resolution (first that applies):
#   $WORKLOG_DIR  →  $WORKLOG_ROOT/docs/worklog  →  $CLAUDE_PROJECT_DIR/docs/worklog
#   →  <git-root>/docs/worklog  →  <cwd>/docs/worklog
#
# Usage:
#   worklog.sh add --title "Short title" \
#       [--type feature|fix|refactor|docs|decision|chore|infra|design|research|note] \
#       [--status done|partial|blocked|wip] \
#       [--tags "comma,separated"] <<'EOF'
#   ### What
#   ...
#   ### Why
#   ...
#   ### How
#   ...
#   ### Outcome
#   ...
#   EOF
#
# The markdown body (the ### sections) is read from stdin. The script stamps the
# timestamp + id, appends to today's file, updates INDEX.md, and prints the id.
set -euo pipefail

resolve_dir() {
  if [ -n "${WORKLOG_DIR:-}" ]; then echo "$WORKLOG_DIR"; return; fi
  local root
  root="${WORKLOG_ROOT:-${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"
  echo "$root/docs/worklog"
}

DIR="$(resolve_dir)"
INDEX="$DIR/INDEX.md"

cmd="${1:-}"; shift || true
[ "$cmd" = "add" ] || { echo "usage: worklog.sh add --title ... [--type ..] [--status ..] [--tags ..] < body" >&2; exit 2; }

title=""; type="note"; status="done"; tags=""
while [ $# -gt 0 ]; do
  case "$1" in
    --title)  title="${2:-}"; shift 2 ;;
    --type)   type="${2:-}"; shift 2 ;;
    --status) status="${2:-}"; shift 2 ;;
    --tags)   tags="${2:-}"; shift 2 ;;
    *) echo "worklog: unknown arg '$1'" >&2; exit 2 ;;
  esac
done
[ -n "$title" ] || { echo "worklog: --title is required" >&2; exit 2; }

body="$(cat || true)"
[ -n "${body//[[:space:]]/}" ] || { echo "worklog: empty body on stdin" >&2; exit 2; }

date="$(date +%F)"
time="$(date +'%H:%M %Z')"
file="$DIR/$date.md"

mkdir -p "$DIR"
if [ ! -f "$file" ]; then
  printf '# Worklog — %s\n\n> Chronological work journal. See [INDEX.md](./INDEX.md) for the\n> cross-entry map. Format: the `worklog` skill.\n' "$date" > "$file"
fi

# Next sequence number for today (zero-padded).
n="$(grep -c "· WL-$date-" "$file" 2>/dev/null || true)"; n="${n:-0}"
id="$(printf 'WL-%s-%03d' "$date" "$((n + 1))")"

# Append the entry.
{
  printf '\n## %s · %s · %s\n\n' "$time" "$id" "$title"
  meta="**Type:** $type · **Status:** $status"
  [ -n "$tags" ] && meta="$meta · **Tags:** $tags"
  printf '%s\n\n' "$meta"
  printf '%s\n\n' "$body"
  printf -- '---\n'
} >> "$file"

# Update the index (group by date heading; entries appended chronologically).
if [ ! -f "$INDEX" ]; then
  printf '# Worklog Index\n\nOne line per entry, grouped by day. Each links to its day file; grep the id within\nthat file for the full entry. Start here to get up to speed on the project.\n\n## Entries\n' > "$INDEX"
fi
last_heading="$(grep '^## ' "$INDEX" 2>/dev/null | tail -1 || true)"
[ "$last_heading" = "## $date" ] || printf '\n## %s\n' "$date" >> "$INDEX"
printf -- '- [%s](./%s.md) — %s — _%s/%s_\n' "$id" "$date" "$title" "$type" "$status" >> "$INDEX"

echo "$id  ($file)"

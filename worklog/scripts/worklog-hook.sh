#!/usr/bin/env bash
#
# worklog-hook.sh — Stop-hook backstop for the work journal (repo-agnostic).
#
# A hook cannot write the what/why/how narrative (only the agent can), so this is a
# lightweight, NON-blocking nudge — not the primary mechanism. It reminds when work has
# happened today (a commit since midnight, or uncommitted changes) but today's journal
# file does not exist yet. Once today's file exists, it stays quiet. The per-response
# logging discipline itself lives in the worklog skill / your CLAUDE.md.
#
# Wire it as a global or per-project Stop hook (see the skill's README / install.sh).
set -uo pipefail

ROOT="${WORKLOG_ROOT:-${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}}"
cd "$ROOT" 2>/dev/null || exit 0
# Only relevant inside a git repo (where "work today" is detectable). Quiet otherwise.
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

DIR="${WORKLOG_DIR:-$ROOT/docs/worklog}"
today="$DIR/$(date +%F).md"

# Already journaling today — rely on the per-response rule for the rest. Quiet.
[ -f "$today" ] && exit 0

# No journal yet today: only nudge if there has actually been work today.
has_work=0
git log --since=midnight --oneline 2>/dev/null | grep -q . && has_work=1
[ -n "$(git status --porcelain 2>/dev/null)" ] && has_work=1
[ "$has_work" = 1 ] || exit 0

echo "📓 worklog reminder: no $today yet today. Capture this work with the worklog skill (scripts/worklog.sh add --title ... — what/why/how/outcome on stdin)."
exit 0

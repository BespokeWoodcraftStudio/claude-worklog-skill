#!/usr/bin/env bash
#
# install.sh — install the worklog skill globally, or into a single project.
#
#   ./install.sh                  GLOBAL: ~/.claude/skills + a rule in ~/.claude/CLAUDE.md
#                                 (available in every repo, every session)
#   ./install.sh --project [DIR]  PROJECT-ONLY: <DIR>/.claude/skills + a rule in <DIR>/CLAUDE.md
#                                 (just that repo; DIR defaults to the current git repo / cwd)
#   ./install.sh --hook           also wire a non-blocking Stop-hook reminder (settings.json)
#   ./install.sh --no-rule        install the skill files only, without touching CLAUDE.md
#
# Adding the CLAUDE.md rule is the default so the skill is used automatically. All steps
# are idempotent — safe to re-run to update.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

scope="global"; proj_dir=""; want_rule=1; want_hook=0
while [ $# -gt 0 ]; do
  case "$1" in
    --global)  scope="global" ;;
    --project) scope="project"
               if [ -n "${2:-}" ] && [ "${2#-}" = "${2:-}" ]; then proj_dir="$2"; shift; fi ;;
    --no-rule) want_rule=0 ;;
    --rule)    want_rule=1 ;;
    --hook)    want_hook=1 ;;
    -h|--help) sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "install: unknown option '$1' (try --help)" >&2; exit 2 ;;
  esac
  shift
done

# Resolve install locations + the script path the CLAUDE.md rule should reference.
if [ "$scope" = "global" ]; then
  BASE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
  DEST="$BASE/skills/worklog"
  MD="$BASE/CLAUDE.md"
  SETTINGS="$BASE/settings.json"
  SCRIPT_REF='"$HOME/.claude/skills/worklog/scripts/worklog.sh"'
  HOOK_REF='bash "$HOME/.claude/skills/worklog/scripts/worklog-hook.sh"'
  where="globally (all repos, all sessions)"
else
  root="${proj_dir:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  root="$(cd "$root" && pwd)"
  DEST="$root/.claude/skills/worklog"
  MD="$root/CLAUDE.md"
  SETTINGS="$root/.claude/settings.json"
  SCRIPT_REF='.claude/skills/worklog/scripts/worklog.sh'
  HOOK_REF='bash "${CLAUDE_PROJECT_DIR:-.}/.claude/skills/worklog/scripts/worklog-hook.sh"'
  where="for project: $root"
fi

# 1) Install the skill files.
mkdir -p "$DEST/scripts"
cp -R "$HERE/worklog/." "$DEST/"
chmod +x "$DEST/scripts/"*.sh
echo "✓ skill installed → $DEST  ($where)"

# 2) Add the CLAUDE.md rule (idempotent) so the agent logs automatically.
emit_rule() {
  cat <<'RULE'

<!-- worklog-skill:begin -->
## Work journal (worklog)

At the END of each substantive response (a fix, feature step, decision, or research
finding — not trivial/chat turns), append a work-journal entry:

```bash
__WORKLOG_SCRIPT__ add --title "..." --type <feature|fix|refactor|docs|decision|chore|infra|design|research|note> --status <done|partial|blocked|wip> <<'EOF'
### What … ### Why … ### How … ### Outcome …
EOF
```

What/Why/How/Outcome are required; add Decisions/Lessons/Follow-ups/Links when relevant.
The journal lives at `docs/worklog/` in the current repo. When getting up to speed on a
project, **read `docs/worklog/INDEX.md` first**. Full format: the `worklog` skill (`/worklog`).
<!-- worklog-skill:end -->
RULE
}
if [ "$want_rule" = 1 ]; then
  touch "$MD"
  if grep -q 'worklog-skill:begin' "$MD" 2>/dev/null; then
    echo "• CLAUDE.md rule already present (skipped) → $MD"
  else
    emit_rule | sed "s|__WORKLOG_SCRIPT__|$SCRIPT_REF|g" >> "$MD"
    echo "✓ CLAUDE.md rule added → $MD (entries written automatically)"
  fi
fi

# 3) Optional: Stop-hook reminder (idempotent JSON merge).
if [ "$want_hook" = 1 ]; then
  python3 - "$SETTINGS" "$HOOK_REF" <<'PY'
import json, os, sys
p, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(p):
    with open(p) as f:
        try: data = json.load(f)
        except Exception: data = {}
stop = data.setdefault("hooks", {}).setdefault("Stop", [])
if any("worklog-hook.sh" in h.get("command","") for g in stop for h in g.get("hooks", [])):
    print("• Stop hook already present (skipped) →", p)
else:
    stop.append({"hooks":[{"type":"command","command":cmd,"timeout":15,"statusMessage":"worklog check"}]})
    os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
    with open(p,"w") as f:
        json.dump(data, f, indent=2); f.write("\n")
    print("✓ Stop hook wired →", p)
PY
fi

echo "Done. worklog installed $where."
[ "$want_rule" = 1 ] && echo "  • CLAUDE.md updated — entries are written automatically."
[ "$want_hook" = 1 ] || echo "  • Tip: re-run with --hook to also add a Stop-hook reminder."
[ "$scope" = "project" ] && echo "  • Commit .claude/skills/worklog/ and CLAUDE.md to share it with the repo."
exit 0

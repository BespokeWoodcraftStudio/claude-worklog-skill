#!/usr/bin/env bash
#
# install.sh — install the worklog skill into ~/.claude/skills (user-global).
#
#   ./install.sh            copy the skill into ~/.claude/skills/worklog
#   ./install.sh --rule     also add a "log every response" rule to ~/.claude/CLAUDE.md
#   ./install.sh --hook     also wire a non-blocking Stop-hook reminder (~/.claude/settings.json)
#   ./install.sh --rule --hook
#
# All steps are idempotent — safe to re-run to update.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
DEST="$CLAUDE_HOME/skills/worklog"

want_rule=0; want_hook=0
for a in "$@"; do
  case "$a" in
    --rule) want_rule=1 ;;
    --hook) want_hook=1 ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "install: unknown option '$a' (try --help)" >&2; exit 2 ;;
  esac
done

# 1) Install the skill files.
mkdir -p "$DEST/scripts"
cp -R "$HERE/worklog/." "$DEST/"
chmod +x "$DEST/scripts/"*.sh
echo "✓ skill installed → $DEST"

# 2) Optional: global CLAUDE.md rule (idempotent via markers).
if [ "$want_rule" = 1 ]; then
  md="$CLAUDE_HOME/CLAUDE.md"
  touch "$md"
  if grep -q 'worklog-skill:begin' "$md" 2>/dev/null; then
    echo "• CLAUDE.md rule already present (skipped)"
  else
    cat >> "$md" <<'RULE'

<!-- worklog-skill:begin -->
## Work journal (worklog)

At the END of each substantive response (a fix, feature step, decision, or research
finding — not trivial/chat turns), append a work-journal entry:

```bash
"$HOME/.claude/skills/worklog/scripts/worklog.sh" add --title "..." --type <feature|fix|refactor|docs|decision|chore|infra|design|research|note> --status <done|partial|blocked|wip> <<'EOF'
### What … ### Why … ### How … ### Outcome …
EOF
```

What/Why/How/Outcome are required; add Decisions/Lessons/Follow-ups/Links when relevant.
The journal lives at `docs/worklog/` in the current repo. When getting up to speed on a
project, **read `docs/worklog/INDEX.md` first**. Full format: the `worklog` skill (`/worklog`).
<!-- worklog-skill:end -->
RULE
    echo "✓ CLAUDE.md rule added → $md"
  fi
fi

# 3) Optional: global Stop-hook reminder (idempotent JSON merge).
if [ "$want_hook" = 1 ]; then
  python3 - "$CLAUDE_HOME/settings.json" <<'PY'
import json, os, sys
p = sys.argv[1]
data = {}
if os.path.exists(p):
    with open(p) as f:
        try: data = json.load(f)
        except Exception: data = {}
stop = data.setdefault("hooks", {}).setdefault("Stop", [])
present = any("worklog-hook.sh" in h.get("command","")
             for g in stop for h in g.get("hooks", []))
if present:
    print("• Stop hook already present (skipped)")
else:
    stop.append({"hooks":[{"type":"command",
        "command":'bash "$HOME/.claude/skills/worklog/scripts/worklog-hook.sh"',
        "timeout":15,"statusMessage":"worklog check"}]})
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p,"w") as f:
        json.dump(data, f, indent=2); f.write("\n")
    print("✓ Stop hook wired →", p)
PY
fi

echo "Done. The 'worklog' skill is now available in all your Claude Code sessions."
[ "$want_rule" = 1 ] || echo "Tip: re-run with --rule to log automatically, --hook for a reminder."

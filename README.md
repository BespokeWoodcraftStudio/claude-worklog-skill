# worklog — a work-journal skill for Claude Code

A tiny, portable [Claude Code](https://claude.com/claude-code) skill that gives any
project a **work journal**: a committed, cross-linked record of *what* was done, *why*,
and *how*. Install it once and it works in **every repo** — at the end of each
substantial piece of work, the agent appends a structured, timestamped entry.

Source code tells you *what* the code does. The work journal tells you *why it's like
that* — the question that costs the most time when you (or an AI) come back to a project
cold. The journal is the fastest way to get back up to speed.

> Inspired by [Architecture Decision Records](https://adr.github.io/) and the
> "compound engineering" idea that an agent should get smarter every time it's corrected.

---

## What an entry looks like

Entries live in `docs/worklog/YYYY-MM-DD.md` (one file per day) with a running
`docs/worklog/INDEX.md` map. Each entry has a stable id (`WL-2026-06-03-002`) so it can
be linked from other entries and commits.

```markdown
## 14:21 PDT · WL-2026-06-03-002 · Re-theme UI to match the product dashboard

**Type:** design · **Status:** done · **Tags:** ui,branding

### What
Recolored the app to a navy/blue scheme with green reserved for success states.

### Why
The tool should visually match the product the operator actually uses.

### How
Sampled the reference colors live, updated the design tokens in tailwind.config.ts and
globals.css (kept in sync), plus the app icon. No component hardcodes colors.

### Outcome
done — verified in-browser against the reference.

### Lessons / gotchas
"Match the brand colors" is ambiguous — the marketing site and the product UI differ.
Always confirm which surface.

### Links
[[WL-2026-06-03-001]] · commit:a74ac08
```

**What / Why / How / Outcome** are required; **Decisions & trade-offs**, **Lessons /
gotchas**, **Follow-ups**, and **Links** are added when relevant.

---

## Install

```bash
git clone https://github.com/<you>/claude-worklog-skill.git
cd claude-worklog-skill
./install.sh            # copies the skill into ~/.claude/skills/worklog
```

That makes the `worklog` skill available in **all** your Claude Code sessions on this
machine (it's a user-level skill in `~/.claude/skills/`).

Optional flags make it fully hands-off:

```bash
./install.sh --rule     # also add a rule to ~/.claude/CLAUDE.md so the agent logs every
                        # substantive response, in every project, by default
./install.sh --hook     # also wire a global Stop-hook reminder (nudges if a day of work
                        # goes unlogged); non-blocking
./install.sh --rule --hook
```

Manual install (no script): copy the `worklog/` folder to `~/.claude/skills/worklog/`
and `chmod +x ~/.claude/skills/worklog/scripts/*.sh`.

---

## Usage

Once installed, just work. At the end of a substantive response the agent runs:

```bash
~/.claude/skills/worklog/scripts/worklog.sh add --title "..." --type fix --status done <<'EOF'
### What
…
### Why
…
### How
…
### Outcome
…
EOF
```

You can also invoke it yourself with `/worklog`, or run the script directly. The journal
is written to `docs/worklog/` in the current repo.

**Reading the journal:** open `docs/worklog/INDEX.md` and follow the entries that look
relevant. Tell a fresh agent: *"read docs/worklog/INDEX.md to get up to speed."*

### Where the journal goes

Resolved in this order: `$WORKLOG_DIR` → `$WORKLOG_ROOT/docs/worklog` →
`$CLAUDE_PROJECT_DIR/docs/worklog` → `<git root>/docs/worklog` → `<cwd>/docs/worklog`.
Set `WORKLOG_DIR` to put it somewhere custom (or to journal outside a git repo).

---

## How it fits with other memory

The worklog is the **manually-curated narrative** layer. It complements — but doesn't
require — other knowledge layers you may use:

| Layer | Holds | Source |
|---|---|---|
| **worklog** (this) | curated what/why/how narrative | manual |
| auto session memory (e.g. claude-mem) | observations + timeline | automatic |
| fact memory (e.g. memory files) | distilled durable facts | manual |
| code-structure graph (e.g. graphify) | files, symbols, relations | automatic |

Rule of thumb: recall at task **start** (search your auto memory + skim the worklog
index), log at task **end** (write a worklog entry).

---

## Why a hook can't do the whole job

People often ask for "a hook that auto-writes the log." A hook runs a shell command with
no understanding of *why* you did something — only the agent has the reasoning. So the
real mechanism is the skill + a CLAUDE.md rule (the agent writes the entry); the optional
Stop hook is just a **reminder** if a day goes unlogged.

---

## Uninstall

```bash
rm -rf ~/.claude/skills/worklog
# and remove the "worklog" block from ~/.claude/CLAUDE.md and the hook from
# ~/.claude/settings.json if you added them with --rule / --hook.
```

## License

MIT — see [LICENSE](./LICENSE).

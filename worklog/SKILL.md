---
name: worklog
description: Append a structured entry to the project work journal (docs/worklog/) — a committed, cross-linked record of what was done, why, and how. Use at the END of every substantive response, in ANY repo, to capture the work; and to READ the journal (start at docs/worklog/INDEX.md) when getting up to speed on a project.
---

# worklog

A **work journal** is the chronological, cross-linked record of *what* was done in a
project, *why*, and *how*. It is committed to the repo, so it travels with the code and
is the fastest on-ramp for a future session (human or AI) to understand how the project
reached its current state — especially the "why is the code like this?" questions that
source code alone never answers.

This skill is **global and repo-agnostic**: it works in any project. The journal lives
at `docs/worklog/` in the current repo (one file per day + an `INDEX.md` map).

## When to write an entry

At the **end of each substantive response** — after finishing a chunk of work (a fix, a
feature step, a decision, a research finding). Trivial/conversational turns don't need
one. If the user gives you a new task after you responded, that task gets its own entry
when done. One entry per logical unit of work; several per day is normal.

## How to add an entry

Run the bundled script (installed with this skill). The markdown body is read from stdin:

```bash
"$HOME/.claude/skills/worklog/scripts/worklog.sh" add \
    --title "Short, specific title" \
    --type feature|fix|refactor|docs|decision|chore|infra|design|research|note \
    --status done|partial|blocked|wip \
    [--tags "comma,separated"] <<'EOF'
### What
What was done, concretely.

### Why
The motivation / context / problem that prompted it. (The most valuable part for future
understanding — without the "why", a record loses its value as circumstances change.)

### How
The approach and key technical choices. Mention the main files/functions.

### Outcome
Status + how it was verified (build/tests/manual), or what's still open.

### Decisions & trade-offs   (include when a real choice was made)
What was chosen, what was rejected, and why.

### Lessons / gotchas        (include when something was non-obvious or a correction)
Anything a future session should know so it doesn't relearn the hard way. This is the
compounding payoff: the journal gets smarter every time a mistake is corrected.

### Follow-ups               (include when there is unfinished/next work)
- [ ] …

### Links                    (include when related work exists)
[[WL-YYYY-MM-DD-NNN]] other entries · commit:<sha> · file paths
EOF
```

The script stamps the timestamp + a stable id (`WL-YYYY-MM-DD-NNN`), appends to today's
file, updates `docs/worklog/INDEX.md`, and prints the id. **What / Why / How / Outcome
are required**; the rest are included when relevant.

The target directory is the current repo's `docs/worklog/` (resolved from
`$CLAUDE_PROJECT_DIR`, else the git root, else the cwd). Override with `WORKLOG_DIR` for
a non-repo or custom location.

## Linking

- Another entry: `[[WL-2026-06-03-002]]` (just the id).
- A commit: `commit:<sha>`.
- Code: a normal path like `src/server/auth.ts`.

If the project also uses a separate memory or knowledge system, link to it too (e.g.
`mem:<name>` for a file-memory note, `claude-mem:<id>` for a claude-mem observation).

## Reading the journal (getting up to speed)

Start at `docs/worklog/INDEX.md` (one line per entry, grouped by day). Open the day files
that look relevant; grep the entry id inside a day file for the full entry. For "why is
the code like this?" the worklog usually answers faster than reading source.

## Where this fits (optional, if the project uses them)

The worklog is the **manually-curated narrative** layer. It pairs well with, but does not
require, other knowledge layers:

- **Auto-captured session memory** (e.g. claude-mem) — the automatic wide net; worklog is
  the curated highlights of the same history.
- **Distilled fact memory** (e.g. per-project memory files) — atomic durable facts.
- **Code-structure graphs** (e.g. graphify) — where/what the code is.

Run the project's recall step (if any) at task **start**; write a worklog entry at task
**end**.

## Don'ts

- Don't hand-edit `INDEX.md` ids/timestamps — let the script manage them.
- Don't paste large diffs or secrets into an entry; summarize and link the commit.
- Don't skip the entry on real work because "it's small" — the value compounds.

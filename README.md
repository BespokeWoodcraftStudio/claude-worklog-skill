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
git clone https://github.com/BespokeWoodcraftStudio/claude-worklog-skill.git
cd claude-worklog-skill
./install.sh
```

`install.sh` does two things, so the skill is used **automatically**:

1. Installs the `worklog` skill into `~/.claude/skills/worklog` — available in **all**
   your Claude Code sessions on this machine (a user-level skill).
2. **Adds a rule to your `~/.claude/CLAUDE.md`** instructing the agent to append a
   journal entry at the end of each substantive response, in every project.

Both steps are idempotent — re-run any time to update. Options:

```bash
./install.sh --hook      # also wire a non-blocking Stop-hook reminder (nudges if a day
                         # of work goes unlogged)
./install.sh --no-rule   # install the skill files only, without touching CLAUDE.md
```

### Global vs. one project

**Want worklog to be _part of a project_ — committed to the repo and shared with everyone
who clones it? Install it with `--project`.** A global install only sets it up for *you*
on *this* machine; it does **not** travel with the repo.

- **Global** (default) — the skill + CLAUDE.md rule live under `~/.claude/`, so worklog is
  active in **every** repo on your machine, but nothing is added to any repo.
- **`--project`** — installs the skill + rule **into the repo itself**
  (`.claude/skills/worklog/` + `CLAUDE.md` with a repo-relative path). **Commit them**, and
  anyone who clones the repo gets worklog automatically — even if they never installed the
  global skill.

Use `--project`:

```bash
./install.sh --project                 # install into the current repo
./install.sh --project /path/to/repo   # …or a specific repo
./install.sh --project --hook          # + a project-scoped Stop-hook reminder
```

A project install writes into that repo instead of your home dir:

| | Global (default) | `--project` |
|---|---|---|
| Skill files | `~/.claude/skills/worklog/` | `<repo>/.claude/skills/worklog/` |
| Auto-use rule | `~/.claude/CLAUDE.md` | `<repo>/CLAUDE.md` |
| Hook (`--hook`) | `~/.claude/settings.json` | `<repo>/.claude/settings.json` |
| Applies to | every repo | that one repo |

**Commit** `.claude/skills/worklog/` and `CLAUDE.md` after a project install to share the
skill with anyone who clones the repo — it then works even if they never installed the
global one. The scopes are independent: you can keep the global install and still commit
a project copy into a specific repo.

Manual install (no script): copy the `worklog/` folder to `~/.claude/skills/worklog/`
(global) or `<repo>/.claude/skills/worklog/` (project), run `chmod +x` on
`worklog/scripts/*.sh`, and (for auto-use) add a one-line rule to the matching `CLAUDE.md`
telling the agent to run the script at the end of each response.

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

## Works alongside graphify and claude-mem

worklog is a **complementary memory skill**. It's one of a small family of memory /
knowledge tools for Claude Code (and other agents) that overlap a little but each answer
a *different* question. Used together they let an agent — or you — come back to a cold
project and get oriented fast. worklog requires none of them, and adds the layer the
others don't have: the curated **why**. (You don't keep the worklog by hand — **Claude
writes each entry automatically**, at the end of every substantive response, because a
one-line rule in your `CLAUDE.md` codifies it.)

| Tool | Holds | How it's written | Answers | Reach for it when |
|---|---|---|---|---|
| **worklog** (this) | curated narrative — what/why/how, decisions, lessons | **Claude writes it automatically** at the end of each response (curated) | *"how did the project get here, and why was this done?"* | recording a unit of work; understanding the intent behind code |
| **[claude-mem](https://github.com/thedotmack/claude-mem)** | auto-captured observations + a searchable session timeline | auto-captured in the background | *"have we done this before, and how did we solve it?"* | recalling past sessions at the **start** of a task |
| **[graphify](https://github.com/safishamsi/graphify)** | the codebase's structure — files, symbols, call/concept relationships, central "god nodes", clusters | auto-generated from code | *"where is X, and how does the code fit together?"* | navigating or mapping unfamiliar code |
| fact memory (e.g. a `memory/` notes folder) | distilled durable facts, preferences, decisions | written deliberately (you or Claude) | *"who owns this / how does the user want it?"* | recalling an atomic fact out of order |

How they complement each other:

- **worklog ↔ [claude-mem](https://github.com/thedotmack/claude-mem)** — both are
  narrative and both are written **by the agent, automatically** — the difference is
  *how*. claude-mem **mechanically captures everything** you do in the background and
  AI-compresses it (the comprehensive net). worklog is a **deliberately authored, curated
  entry** Claude writes at the end of each response — the reasoning, decisions, and
  lessons — committed to the repo so it reads like a changelog of *intent*. Use claude-mem
  to **find** prior work; treat the worklog as the canonical **why**. (A worklog entry can
  even cite a claude-mem observation id.)
- **worklog ↔ [graphify](https://github.com/safishamsi/graphify)** — **orthogonal**.
  graphify answers *where / what* in the code (structure); worklog answers *why* it's that
  way (intent). A worklog entry links to the files; graphify shows how those files relate.
  Structure shifts as code changes; the worklog's reasoning stays true.
- **fact memory** — the place for atomic, durable facts you need out of chronological
  order. When a worklog entry contains one, also write it as a fact and cross-link.

A good loop with all of them:

1. **Start** — search **claude-mem** and skim `docs/worklog/INDEX.md` to recall what was
   done and why.
2. **Work** — use **graphify** to navigate the code (`graphify query` / `path` / `explain`).
3. **End** — write a **worklog** entry; if a durable fact emerged, add a fact-memory note.

All three are independent open-source tools — install whichever you like; worklog works
with or without them.

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
# also remove the worklog-skill block from ~/.claude/CLAUDE.md (added by default),
# and the worklog hook from ~/.claude/settings.json if you installed with --hook.
```

## License

MIT — see [LICENSE](./LICENSE).

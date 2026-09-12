---
name: antigravity-bridge-skill
description: Invoke Google's Antigravity CLI (agy) from inside Claude's own sandbox, authenticated via the user's personal Antigravity subscription sign-in (never an API key). Use this ONLY when the user explicitly asks to use Antigravity CLI, agy, or "this bridge" for a task — never invoke it on your own judgment the way you might reach for a general-purpose tool. Typical explicit phrasings: "Antigravityに聞いて", "agyに投げて", "use antigravity for this", "run this through the antigravity bridge".
---

# antigravity-bridge-skill

Lets you (Claude) call Google's Antigravity CLI (`agy`) from inside your own
sandbox, using the user's real Antigravity subscription sign-in. There is no
API key anywhere in this skill — authentication is a Google OAuth token file
the user generated once on their own machine and bundled into this skill's
`auth/` folder.

## When to use this

**Only when the user explicitly asks for it.** Unlike some bridge skills,
this one is not something you reach for on your own initiative to offload
work or get a second opinion — the user has to name Antigravity / `agy` /
this bridge, or have just picked it from an explicit choice you offered.
If a request is ambiguous about which tool to use, ask; don't assume this
skill applies.

## Before anything else: run setup

At the start of any session where you'll use this skill, run:

```bash
bash scripts/setup.sh
```

This installs `agy` if needed and restores the user's saved token into
`~/.gemini/antigravity-cli/`. If it fails because there's no token file yet,
tell the user to generate one — the repository root has `README.win.md`,
`README.mac.md`, and `README.linux.md` for that. Do not attempt to generate
one from scratch yourself in the middle of a task; that's a deliberate
one-time setup step for the user to do on their own machine.

## Deciding the model and reasoning effort

Every call into `agy` needs a model name and a reasoning effort
(`low`/`medium`/`high`). Resolve them in this order:

1. **The user already said so in this conversation** (a specific model name,
   or "low/medium/high effort", or "use your best judgement" — treat that
   last one as an explicit instruction to pick, not as license to skip
   asking). Use what they said.
2. **Otherwise, ask.** Run `bash scripts/models.sh` first to get the current,
   real list of models (don't rely on memory — Google changes this list
   under this CLI regularly). Then ask the user to choose a model and an
   effort level.
   - If your current environment can present a selectable-choice UI to the
     user (e.g. an interactive multiple-choice question tool), use that —
     it's a better experience than typing the choice out. Offer the models
     `scripts/models.sh` returned, and the three effort levels.
   - If no such UI is available, ask in plain text instead. Still ask; never
     silently default to a model or effort level the user hasn't confirmed.

Never invent a model name that `scripts/models.sh` didn't return.

## Running a single query

```bash
bash scripts/ask.sh --model "<model>" --effort "<low|medium|high>" "<prompt>"
```

Optional flags: `--project <id>`, `--continue`, `--conversation <id>`,
`--output-format text|json`. This script always adds
`--dangerously-skip-permissions` and `--sandbox` — see "Execution policy"
below; you don't need to (and can't opt out by) passing those yourself.

`--print-timeout` on `agy` defaults to 5 minutes. If a query is likely to run
longer than that, use the background job flow instead of a single `ask.sh`
call.

## Running something long: background jobs

Claude's sandbox does not keep a process alive once you finish a turn's tool
calls and let your reply complete. For work that takes a while:

```bash
job_id=$(bash scripts/jobs.sh start --model "<model>" --effort "<effort>" "<prompt>")
bash scripts/wait.sh "$job_id" --timeout 60
```

`wait.sh` polls for up to `--timeout` seconds and tells you whether the job
finished. **If it reports `status: running`, call `wait.sh` again in the
same turn** — keep looping with tool calls, don't end your turn and expect
to pick the job back up cold later; the answer only reaches the user if
you're still there to relay it once `wait.sh` reports `status: done`. Use
`bash scripts/jobs.sh list` to see everything currently tracked, and
`bash scripts/jobs.sh log <job_id>` to peek at partial output.

## Continuing a conversation with agy

`agy` keeps its own multi-turn conversation state, separate from your own
turn-by-turn structure. Use `--continue` (most recent) or
`--conversation <id>` (specific one) with `ask.sh` when the user wants to
keep building on a prior `agy` exchange rather than starting fresh.
`bash scripts/sessions.sh list` gives a best-effort, unofficial peek at
recent conversation IDs.

## Execution policy (deliberate, non-negotiable defaults for this skill)

- **Web search and sandboxed code execution stay on.** Don't pass
  `--disable-slash-commands` or otherwise strip `agy`'s built-in tools
  unless a specific task calls for it. `--sandbox` is always included,
  which keeps terminal command execution inside `agy`'s own restricted
  execution environment.
- **All tool-call approvals are auto-granted, including commands that would
  normally need confirmation** (`--dangerously-skip-permissions`, always
  included by `ask.sh`/`jobs.sh`). This is what the user asked for — there's
  no human present to click "allow" in headless mode anyway — but it means
  `agy` really will run shell commands unattended. If a task looks like it
  could do something destructive (e.g. wide deletions, pushing to a real
  remote, spending money), say so plainly to the user before or as you run
  it, even though nothing will stop the command itself.
- **Never use an API key with `agy`, ever**, even if one is available in the
  environment for some other purpose. Authentication is always the token
  file this skill restores in `setup.sh`.

## If authentication fails

`setup.sh` already checks this, but if a later call suddenly starts failing
with an auth error: the access token expires roughly hourly and `agy`
refreshes it automatically using the stored refresh token, so a bare auth
failure usually means the refresh token itself was revoked (e.g. the user
removed Antigravity's access from their Google Account) rather than simple
expiry. Tell the user plainly and point them at the OS-specific README to
generate a fresh token — don't try to work around it by falling back to an
API key or by fabricating a token file yourself.

## Reference material

`references/agy-cli-reference.md` has the full flag/subcommand list, the
exact on-disk token file shape, and the OAuth parameters `login_helper.py`
uses. Read it if something here isn't enough detail for what you're doing.

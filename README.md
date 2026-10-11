# antigravity-bridge-skill

[日本語版はこちら](./README.ja.md)

A Claude Agent Skill that lets Claude (mobile, web, or any sandbox-based Claude
surface) invoke Google's **Antigravity CLI** (`agy`) using your own Antigravity
**subscription sign-in** — no API key involved.

This mirrors the design of [`codex-bridge-skill`](https://github.com/mokouliszt/codex-bridge-skill),
adapted for `agy`'s OAuth flow and file-based credential storage.

## What this does

- Installs the official `agy` binary inside Claude's sandbox on demand.
- Restores your Antigravity sign-in from a small JSON token file you generate
  once on your own machine (see the OS-specific guides below).
- Runs `agy` non-interactively (`agy -p "..."`) so Claude can ask it questions
  or hand it work, and reads the result back.
- Supports long-running tasks via a background job pattern, since Claude's
  sandbox does not keep a process alive across conversation turns.

## What this intentionally does *not* do

- It never uses an Antigravity/Gemini **API key**. Authentication is always
  through your personal subscription sign-in (the same OAuth flow the `agy`
  CLI itself uses).
- It does not invoke itself automatically. Claude only reaches for this skill
  when you explicitly ask it to use Antigravity / `agy` / Gemini via this
  bridge.

## One-time setup: generating your token

`agy` normally stores your sign-in in your OS's secure keyring (Windows
Credential Manager, macOS Keychain, or a Linux Secret Service). Claude's
sandbox has none of those, so `agy` automatically falls back to a plain,
portable JSON file — but only when no such keyring is reachable. On a
normal desktop this fallback usually never triggers, so you need to generate
the file in an environment that deliberately has no keyring available.

Pick the guide for your OS:

- [Windows](./README.win.md)
- [macOS](./README.mac.md)
- [Linux](./README.linux.md)

Each guide ends with a file named `antigravity-oauth-token`. Drop it into
`skills/antigravity-bridge-skill/auth/antigravity-oauth-token` in **your own,
private copy** of this skill.

## Installing the skill

Each [release](https://github.com/mokouliszt/antigravity-bridge-skill/releases)
has `antigravity-bridge-skill.skill` attached, built from the tagged commit by
GitHub Actions. It contains no credentials, so it cannot sign in on its own.
Build your own package with your token inside:

1. Download or clone this repository, and put your token at
   `skills/antigravity-bridge-skill/auth/antigravity-oauth-token`.
2. Build the private package (Python 3, standard library only):

   ```bash
   python3 .github/scripts/package_skill.py skills/antigravity-bridge-skill \
     --token skills/antigravity-bridge-skill/auth/antigravity-oauth-token
   ```

   This writes `dist/antigravity-bridge-skill-private.skill`.
3. Upload that file to Claude as a skill. If your Claude setup loads skills
   from a folder instead, place `skills/antigravity-bridge-skill/` there with
   the token in its `auth/` folder.
4. In a conversation, explicitly ask Claude to use Antigravity CLI / `agy` /
   this bridge for a task.

## Security notes

- This skill configures `agy` to auto-approve every tool call, including
  shell commands, with no per-action confirmation
  (`--dangerously-skip-permissions`). That is a deliberate, explicit choice
  made for this skill — understand what it means before you use it: `agy`
  will run commands it decides to run, unattended, inside Claude's sandbox.
- Your `antigravity-oauth-token` file is a live credential for your Google
  account (Antigravity's consumer OAuth scope, including
  `cloud-platform`). Treat it like a password. It is excluded from version
  control by `.gitignore` — keep it that way.
- The token includes a refresh token, so it keeps working beyond the short
  lifetime of the access token inside it, until you revoke access from your
  Google Account's third-party access settings.

## Releases

Publishing a release on GitHub runs `.github/workflows/release.yml`, which
attaches `antigravity-bridge-skill.skill` to it. You can also run that workflow
from the Actions tab with a tag name such as `v0.1`: an existing tag is built
as it is, and a new one is created, with its release, on the branch the run
uses.

## License

MIT — see [LICENSE](./LICENSE).

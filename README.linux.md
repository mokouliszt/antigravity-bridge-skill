# Generating `antigravity-oauth-token` on Linux

[日本語版](./README.linux.jp.md) · [Back to main README](./README.md)

`agy` stores your sign-in in a plain JSON file automatically whenever no
D-Bus Secret Service (GNOME Keyring / KWallet) is reachable. Most Linux
desktops *do* have one running, so the safest way to guarantee the file
fallback is a minimal container with no keyring at all — the same setup this
skill uses inside Claude's own sandbox.

## Option A — Docker (recommended, verified)

```bash
docker run --rm -it -v "$PWD":/out debian:bookworm-slim bash
```

Inside the container:

```bash
apt-get update && apt-get install -y curl ca-certificates
curl -fsSL https://antigravity.google/cli/install.sh | bash
export PATH="$HOME/.local/bin:$PATH"
agy
```

`agy` starts its first-run screen and asks you to pick a sign-in method.
Choose **1. Google OAuth**. It prints an authorization URL — open it in any
browser (on your host machine, your phone, wherever), sign in with your
Google account, and it will show you a short code on the resulting page.
Paste that code back into the `agy` prompt.

Once signed in, exit the onboarding (Ctrl+C is fine once you see "Welcome to
Antigravity CLI!" — the token is already written by that point) and copy the
file out to the folder you mounted:

```bash
cp ~/.gemini/antigravity-cli/antigravity-oauth-token /out/antigravity-oauth-token
```

Back on your host, `antigravity-oauth-token` is now in your current
directory (the one you ran `docker run` from).

## Option B — Bare Linux, no desktop keyring

If you're on a headless server, a minimal WM without GNOME Keyring/KWallet,
or you're comfortable temporarily unsetting your session bus, you can skip
Docker:

```bash
env -u DBUS_SESSION_BUS_ADDRESS bash -c '
  curl -fsSL https://antigravity.google/cli/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
  agy
'
```

This isn't guaranteed on every distro (some re-discover a session bus by
other means), so if `agy -p "hi"` still asks you to sign in again afterward,
fall back to Option A.

## Verifying it worked

Before copying the file anywhere, confirm headless mode works with it in
place:

```bash
agy -p "reply with just the word ok"
```

It should print `ok` with no further sign-in prompt.

## What to do with the file

Put it at:

```
skills/antigravity-bridge-skill/auth/antigravity-oauth-token
```


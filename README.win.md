# Generating `antigravity-oauth-token` on Windows

[日本語版](./README.win.jp.md) · [Back to main README](./README.md)

On native Windows, `agy` stores your sign-in in **Windows Credential
Manager**, not a portable file — that's tied to your PC and Windows account
and can't be copied elsewhere. To get the plain, portable JSON file this
skill needs, run `agy` inside a Linux environment that has no keyring
reachable, the same way Claude's own sandbox does it.

## Option A — Docker Desktop (recommended, verified)

1. Install [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
   if you don't have it, and make sure it's running.
2. Open PowerShell or Command Prompt in a folder you don't mind a file
   landing in, then run:

   ```powershell
   docker run --rm -it -v "${PWD}:/out" debian:bookworm-slim bash
   ```

3. Inside the container that opens:

   ```bash
   apt-get update && apt-get install -y curl ca-certificates
   curl -fsSL https://antigravity.google/cli/install.sh | bash
   export PATH="$HOME/.local/bin:$PATH"
   agy
   ```

4. `agy` shows its first-run screen. Choose **1. Google OAuth**. It prints an
   authorization URL — open it in your browser, sign in with your Google
   account, and copy the short code shown on the resulting page back into the
   `agy` prompt.

5. Once you see "Welcome to Antigravity CLI!", the token file already
   exists. Copy it to the folder you mounted:

   ```bash
   cp ~/.gemini/antigravity-cli/antigravity-oauth-token /out/antigravity-oauth-token
   ```

6. Back in Windows, `antigravity-oauth-token` will be in the folder you ran
   `docker run` from.

## Option B — WSL2 (Ubuntu), without Docker

If you already have WSL2 with a plain Ubuntu distro (`wsl --install -d
Ubuntu`) and haven't turned on `systemd=true` in `/etc/wsl.conf`, it
typically has no D-Bus session running, which should give the same file
fallback. This route hasn't been verified as thoroughly as Option A — if
`agy -p "hi"` still prompts you to sign in again, switch to Docker.

1. Open your Ubuntu WSL terminal.
2. Run the same `curl ... | bash` and `agy` steps as above.
3. Copy the resulting file to somewhere Windows can see it:

   ```bash
   cp ~/.gemini/antigravity-cli/antigravity-oauth-token /mnt/c/Users/<you>/antigravity-oauth-token
   ```

## Verifying it worked

Before copying the file anywhere, confirm headless mode accepts it in place:

```bash
agy -p "reply with just the word ok"
```

It should print `ok` with no further sign-in prompt.

## What to do with the file

Put it at:

```
skills/antigravity-bridge-skill/auth/antigravity-oauth-token
```


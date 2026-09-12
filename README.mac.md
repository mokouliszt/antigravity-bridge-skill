# Generating `antigravity-oauth-token` on macOS

[日本語版](./README.mac.jp.md) · [Back to main README](./README.md)

On native macOS, `agy` stores your sign-in in **Keychain**, not a portable
file — that's tied to your Mac and macOS account and can't be copied
elsewhere. To get the plain, portable JSON file this skill needs, run `agy`
inside a Linux container with no keyring reachable, the same way Claude's own
sandbox does it.

## Docker Desktop (recommended, verified)

1. Install [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)
   (or Colima, if you prefer a lighter CLI-only setup) and make sure it's
   running.
2. Open Terminal in a folder you don't mind a file landing in, then run:

   ```bash
   docker run --rm -it -v "$PWD":/out debian:bookworm-slim bash
   ```

3. Inside the container that opens:

   ```bash
   apt-get update && apt-get install -y curl ca-certificates
   curl -fsSL https://antigravity.google/cli/install.sh | bash
   export PATH="$HOME/.local/bin:$PATH"
   agy
   ```

4. `agy` shows its first-run screen. Choose **1. Google OAuth**. It prints an
   authorization URL — open it in your Mac's browser, sign in with your
   Google account, and copy the short code shown on the resulting page back
   into the `agy` prompt.

5. Once you see "Welcome to Antigravity CLI!", the token file already
   exists. Copy it to the folder you mounted:

   ```bash
   cp ~/.gemini/antigravity-cli/antigravity-oauth-token /out/antigravity-oauth-token
   ```

6. Back in macOS, `antigravity-oauth-token` will be in the folder you ran
   `docker run` from (Finder → your Terminal's working directory).

There isn't a lighter-weight, keyring-free path on stock macOS the way there
is with WSL on Windows — Keychain access is effectively always available to
a native macOS process — so a Linux container is the reliable route here.

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


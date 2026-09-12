#!/usr/bin/env bash
# Installs agy (if missing) and restores the user's saved OAuth token into
# this sandbox. Safe to call at the start of every session — idempotent.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
AUTH_SRC="$SKILL_DIR/auth/antigravity-oauth-token"
AGY_HOME="$HOME/.gemini/antigravity-cli"
AUTH_DST="$AGY_HOME/antigravity-oauth-token"

echo "== antigravity-bridge-skill setup =="

# 1. Install agy if it isn't already on PATH.
if ! command -v agy >/dev/null 2>&1; then
  echo "-> agy not found, installing..."
  curl -fsSL https://antigravity.google/cli/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
  if ! command -v agy >/dev/null 2>&1; then
    echo "!! agy install finished but 'agy' is still not on PATH."
    echo "   Add \$HOME/.local/bin to PATH and re-run."
    exit 1
  fi
else
  echo "-> agy already installed: $(command -v agy)"
fi

agy --version 2>&1 | head -n1 || true

# 2. Restore the saved token, if we have one and haven't already.
mkdir -p "$AGY_HOME"
if [ -f "$AUTH_SRC" ]; then
  if [ -f "$AUTH_DST" ] && cmp -s "$AUTH_SRC" "$AUTH_DST"; then
    echo "-> token already restored."
  else
    cp "$AUTH_SRC" "$AUTH_DST"
    chmod 600 "$AUTH_DST"
    echo "-> token restored to $AUTH_DST"
  fi
else
  echo "!! No token found at $AUTH_SRC."
  echo "   Generate one on your own machine first — see README.win.md /"
  echo "   README.mac.md / README.linux.md in the repository root — then"
  echo "   place it at that path (never commit it)."
  exit 1
fi

# 3. Sanity check: confirm headless mode is actually authenticated.
echo "-> verifying authentication..."
if agy -p "reply with just the word ok" --dangerously-skip-permissions 2>/tmp/agy-setup-check.err | grep -qi ok; then
  echo "-> OK: agy is authenticated and working."
else
  echo "!! agy did not respond as expected. Output below; the token may be"
  echo "   expired or revoked. Regenerate it (see the OS-specific README)."
  cat /tmp/agy-setup-check.err || true
  exit 1
fi

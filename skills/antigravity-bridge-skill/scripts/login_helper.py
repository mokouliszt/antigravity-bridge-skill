#!/usr/bin/env python3
"""Fallback PKCE login helper for agy's consumer OAuth client.

This is NOT the primary way to produce antigravity-oauth-token — that's a
real native `agy` login on your own machine (see README.win.md / README.mac.md
/ README.linux.md in the repository root). This script exists for the case
where you're already inside a live sandbox session and want to regenerate
raw Google OAuth tokens without leaving it. It performs the token exchange
itself, independent of any running `agy` process, using the same OAuth
parameters `agy`'s own TUI uses (see references/agy-cli-reference.md) — but
it does NOT reproduce agy's exact on-disk token envelope with full
confidence, since that format isn't documented by Google. Use the printed
tokens to hand-assemble a token file matching the shape in
references/agy-cli-reference.md if you go this route, and verify with
`agy -p "..."` before trusting it.

usage:
  python3 login_helper.py gen
      -> prints an authorization URL. Open it in a browser, sign in, and
         copy the code shown on the resulting page.

  python3 login_helper.py exchange "<code>" [--verifier <verifier>]
      -> exchanges the code for tokens and prints them (secrets are not
         echoed in full). Pass --verifier if the state file from `gen`
         didn't survive (e.g. a sandbox reset) — `gen` prints it for
         exactly this reason.
"""
import base64, hashlib, json, os, secrets, sys, urllib.parse, urllib.request, urllib.error

CLIENT_ID = "1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com"
CLIENT_SECRET = "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"
AUTH_URL = "https://accounts.google.com/o/oauth2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
REDIRECT_URI = "https://antigravity.google/oauth-callback"
SCOPE = " ".join([
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile",
    "https://www.googleapis.com/auth/cclog",
    "https://www.googleapis.com/auth/experimentsandconfigs",
    "https://www.googleapis.com/auth/aicode",
    "openid",
])

STATE_DIR = os.path.expanduser("~/.antigravity-bridge")
STATE_FILE = os.path.join(STATE_DIR, "pkce_state.json")


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")


def cmd_gen():
    os.makedirs(STATE_DIR, exist_ok=True)
    verifier = b64url(secrets.token_bytes(64))
    challenge = b64url(hashlib.sha256(verifier.encode()).digest())
    state = b64url(secrets.token_bytes(24))
    with open(STATE_FILE, "w") as f:
        json.dump({"verifier": verifier, "state": state}, f)
    os.chmod(STATE_FILE, 0o600)

    params = {
        "response_type": "code",
        "client_id": CLIENT_ID,
        "redirect_uri": REDIRECT_URI,
        "scope": SCOPE,
        "code_challenge": challenge,
        "code_challenge_method": "S256",
        "state": state,
        "access_type": "offline",
        "prompt": "consent",
    }
    url = AUTH_URL + "?" + urllib.parse.urlencode(params)
    print("== Open this URL in a browser and sign in with Google ==")
    print(url)
    print()
    print("Paste the code shown on the resulting page back to")
    print("`login_helper.py exchange \"<code>\"`.")
    print(f"(verifier, in case this sandbox resets before you exchange: {verifier})")


def cmd_exchange(arg, verifier_override):
    code = arg
    state_in = None
    if "code=" in arg:
        q = urllib.parse.parse_qs(urllib.parse.urlparse(arg).query)
        code = q.get("code", [""])[0]
        state_in = q.get("state", [None])[0]
    if not code:
        sys.exit("ERROR: could not extract an authorization code from the input")

    verifier = verifier_override
    if not verifier:
        try:
            with open(STATE_FILE) as f:
                saved = json.load(f)
            verifier = saved["verifier"]
            if state_in and saved.get("state") and state_in != saved["state"]:
                sys.exit("ERROR: state mismatch. Run `gen` again.")
        except FileNotFoundError:
            sys.exit(
                "ERROR: no pkce_state.json (sandbox likely reset). "
                "Pass --verifier <value> printed by `gen`."
            )

    body = urllib.parse.urlencode({
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": REDIRECT_URI,
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "code_verifier": verifier,
    }).encode()
    req = urllib.request.Request(
        TOKEN_URL, data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            tok = json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"ERROR: token exchange failed {e.code}: {e.read().decode()[:500]}")

    print("=== token exchange succeeded ===")
    print("scope:", tok.get("scope"))
    print("expires_in:", tok.get("expires_in"))
    print("refresh_token present:", bool(tok.get("refresh_token")))

    out_path = os.path.join(STATE_DIR, "raw_token.json")
    with open(out_path, "w") as f:
        json.dump(tok, f, indent=2)
    os.chmod(out_path, 0o600)
    print(f"(raw token saved to {out_path} — not printed in full; treat as secret)")


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "gen":
        cmd_gen()
    elif len(sys.argv) >= 3 and sys.argv[1] == "exchange":
        v = None
        args = sys.argv[2:]
        if "--verifier" in args:
            i = args.index("--verifier")
            v = args[i + 1]
            del args[i:i + 2]
        cmd_exchange(args[0], v)
    else:
        print(__doc__)
        sys.exit(2)

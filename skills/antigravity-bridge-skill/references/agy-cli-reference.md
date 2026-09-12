# agy (Antigravity CLI) reference notes

Captured from a real install (`curl -fsSL https://antigravity.google/cli/install.sh | bash`)
and a completed native login, inside a container with no D-Bus session bus
(the same condition as Claude's sandbox). Antigravity CLI is an actively
developed Google product — re-run `agy --help` and `agy changelog` during
`setup.sh` and diff against this file if something looks off.

## Key flags (`agy --help`)

```
--add-dir                       Add a directory to the workspace (repeatable)
--agent                         Agent for the current CLI session
-c, --continue                  Continue the most recent conversation
--conversation <id>             Resume a previous conversation by ID
--dangerously-skip-permissions  Auto-approve all tool permission requests without prompting
--disable-slash-commands        Disable slash command and skill expansion in print mode
--effort <low|medium|high>      Reasoning effort for the current CLI session
-i, --prompt-interactive        Run an initial prompt interactively and continue the session
--input-format <text|stream-json>
--json-schema <schema>          Enforce structured output (stream-json final result only)
--log-file <path>               Override CLI log file path
--mode <accept-edits|plan>      Agent execution mode for this session
--model <name>                  Model for the current CLI session
--new-project                   Create a new project for this session
--output-format <text|json|stream-json>
-p, --print, --prompt           Run a single prompt non-interactively and print the response
--print-timeout <dur>           Timeout for print mode wait (default 5m0s)
--project <id|name>             Project ID or project name
--sandbox                       Run in a sandbox with terminal restrictions enabled
```

Subcommands: `agent(s)`, `changelog`, `help`, `install`, `mcp`, `mic-serve`,
`models`, `plugin(s)`, `remote-control`, `update`.

`agy models` lists currently available models. Always call this instead of
hardcoding a model list — Google ships new models under this CLI frequently.

## Non-interactive invocation pattern used by this skill

```bash
agy -p "$PROMPT" \
  --model "$MODEL" \
  --effort "$EFFORT" \
  --dangerously-skip-permissions \
  --sandbox \
  --output-format json
```

- `--dangerously-skip-permissions` is required for headless use — there is no
  human present to answer an interactive tool-approval prompt.
- `--sandbox` keeps terminal command execution inside `agy`'s own restricted
  sandbox even though approvals are auto-granted.
- Web search / browser tools are part of `agy`'s built-in toolset and are on
  by default; nothing in this skill disables them. Do not pass
  `--disable-slash-commands` unless a task specifically needs it.

## Authentication

`agy` normally stores OAuth tokens in the OS keyring via a Go keyring
library. When no D-Bus Secret Service session is reachable (headless hosts,
containers — exactly this skill's sandbox), it automatically falls back to a
plain JSON file:

```
~/.gemini/antigravity-cli/antigravity-oauth-token   (chmod 600)
```

Shape (values elided):

```json
{
  "token": {
    "access_token": "ya29....",
    "token_type": "Bearer",
    "refresh_token": "1//....",
    "expiry": "2026-09-12T07:39:14.062692083Z"
  },
  "auth_method": "consumer",
  "id_token": "eyJhbG...."
}
```

This file alone is sufficient for `agy -p ...` to work — first-run onboarding
(color scheme selection, etc.) does **not** need to be completed first.
`setup.sh` restores this file from `auth/antigravity-oauth-token` at the
start of every session, since the sandbox's filesystem does not persist
between Claude conversations.

The access token expires in about an hour; the refresh token lets `agy` mint
new ones on its own as long as the user hasn't revoked access from their
Google Account.

### OAuth parameters (for `scripts/login_helper.py`, used only when
### regenerating a token from inside a live sandbox session)

- Authorization endpoint: `https://accounts.google.com/o/oauth2/auth`
- Token endpoint: `https://oauth2.googleapis.com/token`
- Redirect URI: `https://antigravity.google/oauth-callback` (a real Google
  page — after sign-in it displays the authorization code directly, no
  localhost callback involved)
- Client ID (consumer/"Google OAuth" login path):
  `1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com`
- Client secret (public "installed application" secret embedded in the
  official `agy` binary — Google's own docs describe this class of secret as
  not confidential): `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`
- Scopes: `cloud-platform`, `userinfo.email`, `userinfo.profile`, `cclog`,
  `experimentsandconfigs`, `aicode`, `openid`
- PKCE: S256, `access_type=offline`, `prompt=consent`

This lets `login_helper.py` drive the same flow `agy`'s own TUI uses,
independent of any live `agy` process — important because Claude's sandbox
does not keep a foreground process alive between conversation turns, so the
"show URL → wait for the user to paste a code back" round trip cannot rely on
a still-running `agy`.

`login_helper.py` performs the token exchange itself but does **not** know
how to reproduce `agy`'s exact on-disk envelope reliably; treat it as a
fallback for regenerating raw Google OAuth tokens, not as the primary path.
The primary, verified path for producing `antigravity-oauth-token` is a real
native `agy` login, documented for each OS in the repository root
(`README.win.md`, `README.mac.md`, `README.linux.md`).

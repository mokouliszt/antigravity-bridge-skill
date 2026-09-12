#!/usr/bin/env bash
# Helpers around agy's conversation continuity.
#
#   sessions.sh list             Best-effort dump of recent conversations
#   sessions.sh continue ...     Shortcut for `ask.sh --continue ...`
#
# agy does not expose a documented "list conversations" subcommand as of
# this writing. It does keep a local sqlite summary DB, so `list` reads that
# directly, defensively (schema isn't officially documented — this may
# break on a future agy update; if it does, `--continue` / `--conversation
# <id>` still work regardless).
set -euo pipefail

AGY_HOME="$HOME/.gemini/antigravity-cli"
DB="$AGY_HOME/conversation_summaries.db"

cmd="${1:-list}"
shift || true

case "$cmd" in
  list)
    if [ ! -f "$DB" ]; then
      echo "No conversation history yet at $DB."
      exit 0
    fi
    if ! command -v sqlite3 >/dev/null 2>&1; then
      echo "sqlite3 isn't installed in this sandbox; can't read $DB."
      echo "You can still resume the most recent conversation with:"
      echo "  agy --continue -p \"...\" --model <model> --effort <effort>"
      exit 0
    fi
    TABLE="$(sqlite3 "$DB" ".tables" | tr ' ' '\n' | grep -i conversation | head -n1 || true)"
    if [ -z "$TABLE" ]; then
      echo "Couldn't find a conversation table in $DB. Tables present:"
      sqlite3 "$DB" ".tables"
      exit 0
    fi
    echo "== last 10 rows of '$TABLE' (schema may change between agy versions) =="
    sqlite3 -header -column "$DB" "SELECT * FROM $TABLE ORDER BY rowid DESC LIMIT 10;"
    ;;
  continue)
    exec "$(dirname "${BASH_SOURCE[0]}")/ask.sh" --continue "$@"
    ;;
  *)
    echo "Usage: sessions.sh {list|continue ...}" >&2
    exit 2
    ;;
esac

#!/usr/bin/env bash
# Background jobs for long-running agy work.
#
# Claude's sandbox does not keep a process alive once Claude finishes a
# turn's tool calls, so a long `agy -p ...` call started with a plain `&`
# is not reliable across turns. This double-forks/detaches the job the same
# way an init system would, so it survives independently of the shell that
# launched it. Pair with wait.sh, called repeatedly *within the same turn*
# (never end the turn while still waiting — that's what actually breaks
# continuity, not process detachment itself).
#
# Usage:
#   jobs.sh start --model <name> --effort <low|medium|high> "<prompt>" [ask.sh flags...]
#   jobs.sh list
#   jobs.sh log <job_id> [n_lines]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS_DIR="$HOME/.antigravity-bridge/jobs"
mkdir -p "$JOBS_DIR"

cmd="${1:-}"
shift || true

case "$cmd" in
  start)
    job_id="job_$(date +%s)_$$"
    job_dir="$JOBS_DIR/$job_id"
    mkdir -p "$job_dir"
    printf '%s\n' "$@" > "$job_dir/cmd.txt"

    python3 - "$job_dir" "$SCRIPT_DIR/ask.sh" "$@" <<'PYEOF'
import os, sys

job_dir, ask_sh, *ask_args = sys.argv[1:]
log_path = os.path.join(job_dir, "output.log")
pid_path = os.path.join(job_dir, "pid")
done_path = os.path.join(job_dir, "done")

if os.fork() > 0:
    sys.exit(0)
os.setsid()
if os.fork() > 0:
    sys.exit(0)

devnull = os.open(os.devnull, os.O_RDONLY)
log_fd = os.open(log_path, os.O_CREAT | os.O_WRONLY | os.O_TRUNC, 0o600)
os.dup2(devnull, 0)
os.dup2(log_fd, 1)
os.dup2(log_fd, 2)

with open(pid_path, "w") as f:
    f.write(str(os.getpid()))

pid = os.fork()
if pid == 0:
    os.execvp(ask_sh, [ask_sh] + ask_args)
else:
    _, status = os.waitpid(pid, 0)
    with open(done_path, "w") as f:
        f.write(str(os.WEXITSTATUS(status) if os.WIFEXITED(status) else 1))
PYEOF

    echo "$job_id"
    ;;

  list)
    for d in "$JOBS_DIR"/*/; do
      [ -d "$d" ] || continue
      id="$(basename "$d")"
      if [ -f "$d/done" ]; then
        echo "$id  done (exit=$(cat "$d/done"))"
      elif [ -f "$d/pid" ] && kill -0 "$(cat "$d/pid")" 2>/dev/null; then
        echo "$id  running"
      else
        echo "$id  unknown (no pid / process gone, no done marker)"
      fi
    done
    ;;

  log)
    job_id="${1:-}"
    n="${2:-50}"
    [ -z "$job_id" ] && { echo "Usage: jobs.sh log <job_id> [n_lines]" >&2; exit 2; }
    tail -n "$n" "$JOBS_DIR/$job_id/output.log" 2>/dev/null || echo "(no log yet)"
    ;;

  *)
    echo "Usage: jobs.sh {start ...|list|log <job_id> [n_lines]}" >&2
    exit 2
    ;;
esac

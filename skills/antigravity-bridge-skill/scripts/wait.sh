#!/usr/bin/env bash
# Polls a jobs.sh job for up to --timeout seconds (default 60) and reports
# whether it finished. IMPORTANT for whoever/whatever is calling this
# (see SKILL.md): if this returns "running", call wait.sh again in the
# SAME turn rather than ending your turn and coming back later — the
# background job keeps running fine either way, but reading its result
# back into the conversation requires you to still be looping.
#
# Usage: wait.sh <job_id> [--timeout SECONDS] [--poll SECONDS]
set -euo pipefail

JOBS_DIR="$HOME/.antigravity-bridge/jobs"
job_id="${1:-}"
shift || true
[ -z "$job_id" ] && { echo "Usage: wait.sh <job_id> [--timeout SECONDS] [--poll SECONDS]" >&2; exit 2; }

TIMEOUT=60
POLL=2
while [ $# -gt 0 ]; do
  case "$1" in
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --poll) POLL="$2"; shift 2 ;;
    *) shift ;;
  esac
done

job_dir="$JOBS_DIR/$job_id"
[ -d "$job_dir" ] || { echo "!! no such job: $job_id" >&2; exit 2; }

elapsed=0
while [ "$elapsed" -lt "$TIMEOUT" ]; do
  if [ -f "$job_dir/done" ]; then
    echo "status: done"
    echo "exit_code: $(cat "$job_dir/done")"
    echo "--- output ---"
    cat "$job_dir/output.log" 2>/dev/null || true
    exit 0
  fi
  sleep "$POLL"
  elapsed=$((elapsed + POLL))
done

echo "status: running"
echo "elapsed: ${elapsed}s (timeout ${TIMEOUT}s)"
echo "--- output so far ---"
tail -n 30 "$job_dir/output.log" 2>/dev/null || echo "(no output yet)"
echo "--- call wait.sh $job_id again in this same turn to keep waiting ---"

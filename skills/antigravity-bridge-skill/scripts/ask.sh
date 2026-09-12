#!/usr/bin/env bash
# Runs a single non-interactive agy prompt and prints the response.
# Model and reasoning effort are REQUIRED arguments on purpose: this skill
# never guesses them. SKILL.md instructs Claude to get them from the user
# first (explicit instruction, or by asking) before calling this script.
#
# Usage:
#   ask.sh --model <name> --effort <low|medium|high> "<prompt>" \
#          [--project <id>] [--continue] [--conversation <id>] \
#          [--output-format text|json]
set -euo pipefail

MODEL=""
EFFORT=""
PROJECT=""
CONVERSATION=""
CONTINUE_FLAG=""
OUTPUT_FORMAT="text"
PROMPT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --effort) EFFORT="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --conversation) CONVERSATION="$2"; shift 2 ;;
    --continue) CONTINUE_FLAG="--continue"; shift ;;
    --output-format) OUTPUT_FORMAT="$2"; shift 2 ;;
    *) PROMPT="$1"; shift ;;
  esac
done

if [ -z "$MODEL" ] || [ -z "$EFFORT" ]; then
  echo "!! --model and --effort are both required." >&2
  echo "   Run scripts/models.sh to see available models, and ask the user" >&2
  echo "   which model + reasoning effort (low/medium/high) to use if they" >&2
  echo "   haven't already said." >&2
  exit 2
fi

if [ -z "$PROMPT" ]; then
  echo "!! no prompt given." >&2
  exit 2
fi

ARGS=(-p "$PROMPT" --model "$MODEL" --effort "$EFFORT"
      --dangerously-skip-permissions --sandbox
      --output-format "$OUTPUT_FORMAT")

[ -n "$PROJECT" ] && ARGS+=(--project "$PROJECT")
[ -n "$CONVERSATION" ] && ARGS+=(--conversation "$CONVERSATION")
[ -n "$CONTINUE_FLAG" ] && ARGS+=("$CONTINUE_FLAG")

exec agy "${ARGS[@]}"

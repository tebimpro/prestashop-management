#!/usr/bin/env bash
#
# © Tebim sp. z o.o. | tebim.pro — BSD-2-Clause
#
# Stop hook for the controlling-prestashop skill.
# If this session performed a lot of PrestaShop mutations via psctl (a long,
# repetitive job), prompt Claude ONCE to offer the user a reusable note/script
# so the same work is faster next time. Silent no-op otherwise.
#
# Signal: new lines in .psctl/audit.log since SessionStart (set by session-start.sh).
# Tunable: PSCTL_OPTIMIZE_THRESHOLD (default 10 mutations).
#
set -euo pipefail

THRESHOLD="${PSCTL_OPTIMIZE_THRESHOLD:-10}"
STATE_DIR="${PSCTL_HOOK_STATE:-${TMPDIR:-/tmp}/psctl-hooks}"

input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1; }
sid=$(field session_id)
cwd=$(field cwd)

log="${cwd:-.}/${PSCTL_LOG_DIR:-.psctl}/audit.log"
now=0; [ -f "$log" ] && now=$(wc -l < "$log" | tr -d ' ')

base=0
[ -f "$STATE_DIR/${sid:-unknown}.base" ] && base=$(cat "$STATE_DIR/${sid:-unknown}.base")

delta=$(( now - base ))
[ "$delta" -ge "$THRESHOLD" ] || exit 0

marker="$STATE_DIR/${sid:-unknown}.prompted"
[ -f "$marker" ] && exit 0            # prompt only once per session
mkdir -p "$STATE_DIR"; : > "$marker"

# reason: plain text, no double quotes/backslashes so it embeds safely in JSON.
reason="This session performed $delta PrestaShop mutations via psctl -- a long, repetitive job. Before stopping, ask the user whether to analyze what was done (see .psctl/audit.log) and save a reusable note or script under ./.psctl/notes/ (named after the task) so the same work is faster next time. If the user declines, just stop."

printf '{"decision":"block","reason":"%s"}\n' "$reason"
exit 0

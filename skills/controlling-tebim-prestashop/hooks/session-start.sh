#!/usr/bin/env bash
#
# © Tebim sp. z o.o. | tebim.pro — BSD-2-Clause
#
# SessionStart hook for the controlling-prestashop skill.
# Records the baseline size of the store's audit log at session start, so the
# Stop hook can tell how many PrestaShop mutations THIS session performed.
# No-op (and harmless) when the skill / psctl isn't used.
#
set -euo pipefail

STATE_DIR="${PSCTL_HOOK_STATE:-${TMPDIR:-/tmp}/psctl-hooks}"

input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1; }
sid=$(field session_id)
cwd=$(field cwd)

log="${cwd:-.}/${PSCTL_LOG_DIR:-.psctl}/audit.log"
n=0; [ -f "$log" ] && n=$(wc -l < "$log" | tr -d ' ')

mkdir -p "$STATE_DIR"
printf '%s' "$n" > "$STATE_DIR/${sid:-unknown}.base"
exit 0

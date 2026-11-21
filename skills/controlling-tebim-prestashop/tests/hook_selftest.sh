#!/usr/bin/env bash
#
# © Tebim sp. z o.o. | tebim.pro — BSD-2-Clause
#
# Offline check for the session hooks: baseline capture, threshold trigger,
# once-per-session, and below-threshold silence. No Claude, no network.
#
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
HOOKS="$here/../hooks"

fails=0
check() { if [ "$2" = "$3" ]; then printf 'ok   %s\n' "$1"
  else printf 'FAIL %s\n  got:[%s]\n want:[%s]\n' "$1" "$2" "$3"; fails=$((fails+1)); fi; }

work=$(mktemp -d); state=$(mktemp -d); mkdir -p "$work/.psctl"

sid=s1; inp="{\"session_id\":\"$sid\",\"cwd\":\"$work\"}"

# SessionStart with empty log -> baseline 0
printf '%s' "$inp" | PSCTL_HOOK_STATE="$state" bash "$HOOKS/session-start.sh"
check "baseline recorded" "$(cat "$state/$sid.base")" "0"

# 10 mutations this session -> Stop triggers (threshold 10), emits block JSON
for i in $(seq 1 10); do echo "m$i" >> "$work/.psctl/audit.log"; done
out=$(printf '%s' "$inp" | PSCTL_HOOK_STATE="$state" PSCTL_OPTIMIZE_THRESHOLD=10 bash "$HOOKS/session-optimizer.sh")
printf '%s' "$out" | grep -q '"decision":"block"' && check "triggers at threshold" yes yes || check "triggers at threshold" no yes

# Second Stop in same session -> silent (once per session)
out2=$(printf '%s' "$inp" | PSCTL_HOOK_STATE="$state" PSCTL_OPTIMIZE_THRESHOLD=10 bash "$HOOKS/session-optimizer.sh")
check "fires once" "$out2" ""

# New session, baseline now 10, only +1 mutation -> below threshold, silent
sid2=s2; inp2="{\"session_id\":\"$sid2\",\"cwd\":\"$work\"}"
printf '%s' "$inp2" | PSCTL_HOOK_STATE="$state" bash "$HOOKS/session-start.sh"
echo "m11" >> "$work/.psctl/audit.log"
out3=$(printf '%s' "$inp2" | PSCTL_HOOK_STATE="$state" PSCTL_OPTIMIZE_THRESHOLD=10 bash "$HOOKS/session-optimizer.sh")
check "below threshold silent" "$out3" ""

rm -rf "$work" "$state"
[ "$fails" -eq 0 ] && { printf '\nall hook checks passed\n'; exit 0; } || { printf '\n%d failed\n' "$fails"; exit 1; }

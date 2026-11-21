#!/usr/bin/env bash
#
# © Tebim sp. z o.o. | tebim.pro — BSD-2-Clause
#
# Offline self-check for psctl: exercises the non-trivial pure logic
# (token masking, query building, url-encoding, base normalization,
# audit log, dry-run) WITHOUT any network. Run: bash tests/selftest.sh
#
# Variables set here are consumed by the sourced psctl functions.
# shellcheck disable=SC2034
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
PSCTL_LIB=1 source "$here/../scripts/psctl"

fails=0
check() { # desc  actual  expected
  if [ "$2" = "$3" ]; then printf 'ok   %s\n' "$1"
  else printf 'FAIL %s\n       got: %s\n  expected: %s\n' "$1" "$2" "$3"; fails=$((fails+1)); fi
}

check "mask long key"        "$(mask 0123456789abcdef)" "0123****ef"
check "mask short key"       "$(mask abc)"              "******"

check "base adds /api"       "$(normalize_base https://shop.test/)"      "https://shop.test/api"
check "base keeps /api"      "$(normalize_base https://shop.test/api)"   "https://shop.test/api"
check "base strips slash"    "$(normalize_base https://shop.test/api/)"  "https://shop.test/api"

check "urlencode space"      "$(urlencode 'a b')"       "a%20b"
check "urlencode keeps []"   "$(urlencode '[id,name]')" "[id,name]"
check "urlencode utf-8"     "$(LC_ALL=C.UTF-8 urlencode 'żółw')" "%C5%BC%C3%B3%C5%82w"

check "query default"        "$(build_query)"                           ""
check "query passthrough"    "$(build_query display=full limit=5)"      "display=full&limit=5"
check "query encodes value"  "$(build_query 'filter[reference]=A B')"   "filter[reference]=A%20B"

# mutation classification
if is_mutation POST; then check "is_mutation POST" yes yes; else check "is_mutation POST" no yes; fi
if is_mutation GET;  then check "is_mutation GET"  yes no;  else check "is_mutation GET"  no no;  fi

# audit log appends a tab-separated line with the expected fields
logd=$(mktemp -d); LOG_DIR="$logd"
audit_log PUT products/42 200 "$logd/snap.xml"
line=$(cat "$logd/audit.log")
check "audit method" "$(printf '%s' "$line" | cut -f2)"  "PUT"          # 1=ts 2=method 3=path 4=code
check "audit path"   "$(printf '%s' "$line" | cut -f3)"  "products/42"
check "audit code"   "$(printf '%s' "$line" | cut -f4)"  "HTTP=200"
rm -rf "$logd"

# dry-run short-circuits mutations before any network call (returns 0, no curl)
PS_URL="https://x/api"; PS_TOKEN="k"
if PSCTL_DRY_RUN=1 http POST products "" >/dev/null 2>&1; then
  check "dry-run skips POST" ok ok
else
  check "dry-run skips POST" fail ok
fi

[ "$fails" -eq 0 ] && { printf '\nall checks passed\n'; exit 0; } || { printf '\n%d check(s) failed\n' "$fails"; exit 1; }

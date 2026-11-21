<!-- © Tebim sp. z o.o. | tebim.pro -->
# API calls — the `curl` playbook (session setup, helpers, every operation)

This file is the single source of truth for **how** to talk to the shop. It
replaces the former `psctl` CLI with plain `curl` plus two small shell helpers
you define inline. Behaviour is identical: XML in/out, `/api` base, audit log,
pre-change snapshots, dry-run, rollback, token never printed.

Requirements: `bash` (3.2+ — macOS default works) and `curl`. `xmllint` is
optional (pretty-printing). Nothing to install.

All state lives in the project's `./.psctl/` directory (gitignored):

| Path | Purpose |
|------|---------|
| `.psctl/base` | API base URL, normalized to end in `/api` |
| `.psctl/curlrc` | curl config holding the key (`chmod 600`) — keeps the key off the command line, out of `ps` and out of the transcript |
| `.psctl/audit.log` | one tab-separated line per `POST`/`PUT`/`DELETE` |
| `.psctl/snapshots/` | XML of each record **before** a `PUT`/`DELETE` |
| `.psctl/last.xml` | body of the last response |
| `.psctl/work/` | scratch XML for writes |
| `.psctl/notes/` | reusable notes/scripts saved after long sessions |

---

## 1. Session setup (once per project — part of `/tebim-prestashop-connect`)

Credentials come from the plugin's userConfig (exposed as
`CLAUDE_PLUGIN_OPTION_PRESTASHOP_URL` / `CLAUDE_PLUGIN_OPTION_PRESTASHOP_TOKEN`)
or from plain `PRESTASHOP_URL` / `PRESTASHOP_TOKEN` environment variables.

```bash
mkdir -p .psctl/snapshots .psctl/work && chmod 700 .psctl
url="${CLAUDE_PLUGIN_OPTION_PRESTASHOP_URL:-${PRESTASHOP_URL:-}}"
key="${CLAUDE_PLUGIN_OPTION_PRESTASHOP_TOKEN:-${PRESTASHOP_TOKEN:-}}"
[ -n "$url" ] || { echo "missing PRESTASHOP_URL"; exit 1; }
[ -n "$key" ] || { echo "missing PRESTASHOP_TOKEN"; exit 1; }
url="${url%/}"; case "$url" in */api) ;; *) url="$url/api" ;; esac
printf '%s\n' "$url" > .psctl/base
( umask 077; printf 'user = "%s:"\n' "$key" > .psctl/curlrc )
grep -qxF '.psctl/' .gitignore 2>/dev/null || echo '.psctl/' >> .gitignore
echo "base: $url   key: ${key:0:4}****${key: -2}"
```

- **Missing URL** → ask the user for it.
- **Missing key** → do **not** ask the user to paste it into the chat. Point them to
  the plugin config field `PRESTASHOP_TOKEN`, or to `export PRESTASHOP_TOKEN=…` in
  their own shell / a `chmod 600` `.env` that you load with `set -a; . ./.env; set +a`.
  No key yet → walk them through `token-setup.md`.
- When you must show the key, show only the mask: first 4 chars + `****` + last 2.
- Never run curl with `-v`, `--trace` or `-u KEY:` — they print or expose the key.
  Always authenticate with `-K .psctl/curlrc`.
- Key rotated? Re-run this block.

## 2. Helpers — paste at the top of every shell call or batch script

Each shell call may start fresh, so define the helpers inline every time.

```bash
B=$(cat .psctl/base); C=.psctl/curlrc

# ps_req METHOD PATH [curl args...] — read. Prints XML; fails on HTTP >= 400.
ps_req() {
  local m="$1" p="${2#/}" code; shift 2
  code=$(curl -sS -g -K "$C" -X "$m" -o .psctl/last.xml -w '%{http_code}' "$@" "$B/$p") || code=000
  if [ "$code" = 000 ] || [ "$code" -ge 400 ]; then
    cat .psctl/last.xml >&2 2>/dev/null; printf '\nHTTP %s\n' "$code" >&2; return 1
  fi
  xmllint --format .psctl/last.xml 2>/dev/null || cat .psctl/last.xml
}

# ps_mut METHOD PATH [BODY] [curl args...] — POST/PUT/DELETE with safety net.
#   BODY: XML file path, "-" for stdin, or "" for none.
#   PSCTL_DRY_RUN=1 -> print the mutation, send nothing.
#   PUT/DELETE -> snapshot the current record first. Always -> audit line.
ps_mut() {
  local m="$1" p="${2#/}" body="${3:-}" snap=- code
  shift 2; [ $# -gt 0 ] && shift
  if [ "${PSCTL_DRY_RUN:-0}" = 1 ]; then
    echo "[dry-run] $m $B/$p ${body:+(body: $body)} (not executed)" >&2; return 0
  fi
  if [ "$m" != POST ]; then   # unique name: never overwrite an earlier snapshot
    local base n=1
    base=".psctl/snapshots/$(date -u +%Y%m%dT%H%M%SZ)-$(printf '%s' "$p" | tr '/ ?&=' '_____')"
    snap="$base.xml"; while [ -e "$snap" ]; do snap="$base-$n.xml"; n=$((n+1)); done
    curl -sSf -g -K "$C" -o "$snap" "$B/$p" 2>/dev/null && [ -s "$snap" ] || { rm -f "$snap"; snap=-; }
  fi
  local args=(-X "$m")
  [ -n "$body" ] && args+=(-H 'Content-Type: text/xml' --data-binary "@$body")
  code=$(curl -sS -g -K "$C" "${args[@]}" "$@" -o .psctl/last.xml -w '%{http_code}' "$B/$p") || code=000
  printf '%s\t%s\t%s\tHTTP=%s\tsnapshot=%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$m" "$p" "$code" "$snap" >> .psctl/audit.log
  if [ "$code" = 000 ] || [ "$code" -ge 400 ]; then
    cat .psctl/last.xml >&2 2>/dev/null; printf '\nHTTP %s\n' "$code" >&2; return 1
  fi
  xmllint --format .psctl/last.xml 2>/dev/null || cat .psctl/last.xml
}
```

Rules:
- **Every** `POST`/`PUT`/`DELETE` goes through `ps_mut` — never a bare `curl -X PUT`.
  That is what guarantees the audit line and the rollback snapshot.
- Reads use `ps_req` (or plain `curl -K .psctl/curlrc`).
- `-g` disables curl's URL globbing so `[` `]` in paths survive.
- Query parameters go through `-G --data-urlencode 'key=value'`: the key stays raw
  (so `filter[name]` works), the value is URL-encoded — including UTF-8
  (`żółw`) and `%` wildcards (sent as `%25`, which is what PrestaShop expects).

## 3. Operation cheat-sheet

```bash
# ping — auth + reachability
ps_req GET "" >/dev/null && echo "OK — authenticated, webservice reachable."

# resources — what this key may access
ps_req GET ""

# list / read
ps_req GET products -G --data-urlencode display=full --data-urlencode limit=5
ps_req GET products -G --data-urlencode 'filter[active]=1' \
  --data-urlencode 'display=[id,reference,price]' --data-urlencode 'sort=[id_DESC]'
ps_req GET orders/42

# schema — XML template for writes (blank) or documented (synopsis)
ps_req GET products -G --data-urlencode schema=blank > .psctl/work/product.xml

# create (POST) — returns the new record with its id
ps_mut POST products .psctl/work/product.xml

# update (PUT) — full replace; round-trip the current record (see §4)
ps_mut PUT products/42 .psctl/work/product-42.xml

# delete
ps_mut DELETE products/42

# body from stdin
some_generator | ps_mut PUT products/42 -

# escape hatch — any method/path/extra curl args (mutations still via ps_mut)
ps_req GET stock_availables -G --data-urlencode 'filter[id_product]=42'
ps_mut POST images/products/42 "" -F 'image=@photo.jpg'

# audit — last N mutations
tail -n 20 .psctl/audit.log

# multistore — target a shop
ps_req GET products/42 -G --data-urlencode id_shop=2
ps_mut PUT 'products/42?id_shop=2' .psctl/work/product-42.xml

# preview a mutation without sending it
PSCTL_DRY_RUN=1 ps_mut DELETE products/42
```

Need JSON for a one-off read? `ps_req GET products/42 -G --data-urlencode output_format=JSON`.
Do not use JSON for writes, snapshots or rollback — XML is authoritative.

## 4. Updating a record (round-trip)

`PUT` replaces the whole record. Always:

```bash
ps_req GET products/42 >/dev/null && cp .psctl/last.xml .psctl/work/product-42.xml
# edit only the fields you change, e.g.:
sed -i.bak 's#<active><!\[CDATA\[1\]\]></active>#<active><![CDATA[0]]></active>#' .psctl/work/product-42.xml
# products: drop read-only fields the API refuses on write
sed -i.bak -e '/<manufacturer_name/d' -e '/<quantity[ >]/d' .psctl/work/product-42.xml
ps_mut PUT products/42 .psctl/work/product-42.xml
```

(`sed -i.bak` works on both macOS and Linux; PrestaShop returns one field per
line, so line-based deletes are safe on its raw output.) Read-only fields differ
between versions (`manufacturer_name`, `quantity`, sometimes
`position_in_category`). If a write fails with “parameter … not writable”,
remove that field from the body and retry.

## 5. Rollback

```bash
tail -n 20 .psctl/audit.log                               # find the snapshot
ps_mut PUT products/42 .psctl/snapshots/<file>.xml        # undo an edit
ps_mut POST products .psctl/snapshots/<file>.xml          # undo a delete (new id!)
ps_mut DELETE products/<id-returned-by-POST>              # undo a create
```

Rollbacks are mutations too — they are logged and snapshotted like any other.

## 6. Self-check before relying on a new environment

```bash
PSCTL_DRY_RUN=1 ps_mut PUT products/1 /dev/null   # prints [dry-run], sends nothing, no audit line
ps_req GET "" >/dev/null && echo ok               # live read works
```

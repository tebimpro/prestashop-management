---
name: controlling-tebim-prestashop
description: Use when controlling, querying, or modifying a PrestaShop store via its legacy Webservice API — reading or writing products, orders, customers, stock, categories or prices over /api (XML), bulk-editing records, or auditing/rolling back shop changes — or when you have (or need to create) a PrestaShop webservice key and shop URL. Use this whenever a task touches a PrestaShop shop's data through its API, even if the user doesn't explicitly say "API".
---

<!-- © Tebim sp. z o.o. | tebim.pro -->

# Controlling PrestaShop (Tebim)

## Overview

Drive a PrestaShop store (1.7 / 8.x / 9.x) through its **legacy Webservice REST API**
with plain `curl` and two inline shell helpers (`ps_req` for reads, `ps_mut` for
writes). Auth is the webservice **key** used as HTTP Basic Auth username (empty
password), kept in a `chmod 600` curl config so it never appears on a command line.
The API speaks **XML** (its native, authoritative format). Needs only `bash` + `curl`
(optional `xmllint`). macOS and Linux.

**Read `references/api-calls.md` before the first API call of a session** — it holds
the setup block, the helpers and every operation. Do not improvise raw `curl` writes.

## When to Use

- List/create/update/delete store data (products, orders, customers, stock, prices, categories, carriers…).
- You have a shop URL + webservice key, or need guidance to create one.
- Scriptable, auditable store operations instead of clicking the back office.

**Not for:** the PrestaShop 9 OAuth2 *Admin API* (different auth/endpoints — out of scope), theme work, or direct DB edits.

## Onboarding a shop (`/tebim-prestashop-connect`)

First time pointing the skill at a shop? Run `/tebim-prestashop-connect` (or just ask to
"connect to the shop"). Procedure:

1. **Shop URL** — from the plugin config, the environment, or ask (e.g. `https://shop.example.com`); `/api` is appended automatically.
2. **Webservice key** — from the plugin config (`PRESTASHOP_TOKEN`, sensitive) or the
   environment. Never ask the user to paste it into the chat; never echo or commit it.
   No key yet → walk them through `references/token-setup.md`.
3. **Session setup** — run the setup block from `references/api-calls.md` §1
   (writes `.psctl/base`, `.psctl/curlrc`, gitignores `.psctl/`).
4. **Verify** — ping (`ps_req GET "" >/dev/null`): auth + reachability.
5. **Scope check** — list resources (`ps_req GET ""`) to confirm what the key may touch.
6. Report back: shop, reachable yes/no, resources available.

## Credentials

- `PRESTASHOP_URL` — e.g. `https://shop.example.com`
- `PRESTASHOP_TOKEN` — the webservice key, marked **sensitive** in the plugin config

The plugin exposes them as `CLAUDE_PLUGIN_OPTION_PRESTASHOP_URL` /
`CLAUDE_PLUGIN_OPTION_PRESTASHOP_TOKEN`; plain `PRESTASHOP_URL` / `PRESTASHOP_TOKEN`
environment variables work too. The setup block reads either. When you need to show
the key, show only its mask (`abcd****yz`).

## Quick Reference

Always prepend the helpers block from `references/api-calls.md` §2.

```bash
ps_req GET "" >/dev/null && echo OK                      # ping
ps_req GET ""                                            # resources
ps_req GET products -G --data-urlencode display=full --data-urlencode limit=5
ps_req GET products -G --data-urlencode 'filter[active]=1' \
  --data-urlencode 'display=[id,reference,price]' --data-urlencode 'sort=[id_DESC]'
ps_req GET orders/42                                     # one record
ps_req GET products -G --data-urlencode schema=blank     # XML template for writes
ps_mut POST products .psctl/work/new-product.xml         # create
ps_mut PUT products/7 .psctl/work/product-7.xml          # update (round-trip!)
ps_mut DELETE products/7                                 # delete
tail -n 50 .psctl/audit.log                              # last 50 mutations
```

Query params (`display`, `filter[...]`, `sort`, `limit`, `schema`, `date`, `id_shop`)
are passed with `-G --data-urlencode` — full syntax in `references/webservice-api.md`.

## How It Works

- Base URL normalized to end in `/api`. Responses are **XML** — PrestaShop's JSON output
  is incomplete/unreliable for many resources, so this skill ignores JSON.
- Writes take XML: fetch a template (`schema=blank`) or the current record, edit it, send it with `ps_mut`.
- `PUT` replaces the whole record — always round-trip (`references/api-calls.md` §4).

## Operating Policies

Mandatory when operating a real store — keeps bulk work safe, reviewable, reversible.
Templates: `references/operating-policies.md`.

### Every mutation goes through `ps_mut`
Never send `POST`/`PUT`/`DELETE` with bare `curl`. `ps_mut` is what writes the audit
line and the rollback snapshot, and honours `PSCTL_DRY_RUN=1`.

### Batch changes (more than a few mutations)
Never fire a dozen ad-hoc commands by hand. Instead:
1. **Generate a reviewable script** (`.psctl/work/<task>.sh`) — helpers block on top, then one `ps_mut` per record or a loop over a data file.
2. **Dry-run it:** `PSCTL_DRY_RUN=1 bash .psctl/work/<task>.sh` — prints every mutation, sends nothing. Show the user the plan.
3. **Run for real** (the script uses `set -euo pipefail`, so a bad record stops the run).

### Auditability (automatic — do not bypass)
Every `POST`/`PUT`/`DELETE` is logged to `./.psctl/audit.log`
(`ts, method, path, HTTP code, snapshot`). Before each `PUT`/`DELETE`, the prior record
is saved as XML under `./.psctl/snapshots/` (unique file names — never overwritten).
- Review: `tail -n 50 .psctl/audit.log`
- **Roll back:** `ps_mut PUT <resource>/<id> .psctl/snapshots/<file>`
- `.psctl/` must be gitignored (snapshots hold store data — possibly customers' personal data).

### Reporting (after any larger job)
End with a short report: scope, counts (created / updated / deleted / failed),
notable per-record outcomes, and rollback pointers (`.psctl/audit.log` + snapshot dir).

**Format depends on where you run — this matters:**
- **Claude Desktop** (can render rich HTML artifacts): emit the report as a styled HTML
  artifact built from `references/report-template.md` — warm neutral canvas, clay
  accent, card layout, light+dark. Use this HTML style **only** in Claude Desktop.
- **Claude Code / terminal / anywhere else:** plain **Markdown** (template in
  `references/operating-policies.md`). Do **not** emit the HTML there — it renders as raw tags.

### Learning from long sessions
Before the first mutation in a task, note the baseline:
`wc -l < .psctl/audit.log` (0 if the file doesn't exist). When the task is done,
compare again. If this session added **10 or more** mutations (a long, repetitive
job), offer the user **once**: analyze what was done (see `.psctl/audit.log`) and
**save a reusable note or script** under `./.psctl/notes/` (named after the task)
so the same work is faster next time. If the user declines, move on.

## Reference Files

- `references/api-calls.md` — **setup, `ps_req`/`ps_mut` helpers, every operation, round-trip updates, rollback.**
- `references/webservice-api.md` — resources, HTTP methods, filter/display/sort/limit syntax, XML format, common errors.
- `references/token-setup.md` — creating & scoping a webservice key, enabling the webservice, host gotchas.
- `references/operating-policies.md` — batch-script skeleton, dry-run workflow, rollback, Markdown report.
- `references/report-template.md` — HTML report template (Claude Desktop only).

## Verify

`PSCTL_DRY_RUN=1 ps_mut PUT products/1 /dev/null` must print `[dry-run]` and send
nothing; `ps_req GET "" >/dev/null && echo ok` checks a live store.

## Common Mistakes

- **401/Unauthorized** — key wrong, webservice disabled, or `http://` where SSL is required.
- **403** — the key lacks that resource/method in its permission grid.
- **404 on /api** — the host must route `/api` (URL rewriting / `.htaccess` / nginx rules).
- **Writes rejected** — body must be valid webservice XML; start from `schema=blank` or the current record; drop read-only fields.
- **`-v` / `--trace` / `-u KEY:`** — never: they print or expose the key. Use `-K .psctl/curlrc`.
- **Empty/odd JSON** — don't; PrestaShop JSON is unreliable. This skill uses XML.

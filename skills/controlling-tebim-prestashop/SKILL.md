---
name: controlling-tebim-prestashop
description: Use when controlling, querying, or modifying a PrestaShop store from the command line via its legacy Webservice API — reading or writing products, orders, customers, stock, categories or prices over /api (XML), bulk-editing records, or auditing/rolling back shop changes — or when you have (or need to create) a PrestaShop webservice key and shop URL. Use this whenever a task touches a PrestaShop shop's data through its API, even if the user doesn't explicitly say "API" or "psctl".
---

# Controlling PrestaShop (Tebim)

## Overview

Drive a PrestaShop store (1.7 / 8.x / 9.x) through its **legacy Webservice REST API**
using one bash CLI, `scripts/psctl`. Auth is the webservice **key** used as HTTP
Basic Auth username (empty password). The API speaks **XML** (its native, authoritative
format). No dependencies beyond `curl` (optional `xmllint` for pretty XML). Runs on
macOS (bash 3.2) and Linux.

## When to Use

- List/create/update/delete store data (products, orders, customers, stock, prices, categories, carriers…) programmatically.
- You have a shop URL + webservice key, or need guidance to create one.
- Scriptable, auditable store operations instead of clicking the back office.

**Not for:** the PrestaShop 9 OAuth2 *Admin API* (different auth/endpoints — out of scope), theme work, or direct DB edits.

## Onboarding a shop (`/tebim-prestashop-connect`)

First time pointing the skill at a shop? Run `/tebim-prestashop-connect` (or just ask to
"connect to the shop"). Procedure:

1. **Shop URL** — ask for it (e.g. `https://shop.example.com`); `/api` is appended automatically.
2. **Webservice key** — if the user has none, walk them through `scripts/psctl token-help`
   (Advanced Parameters → Webservice → enable + add key, least-privilege permissions).
   Put the URL + key in the plugin's userConfig fields (token is `sensitive`) — never echo it, never commit it.
3. **Verify** — `scripts/psctl ping` (auth + reachability).
4. **Scope check** — `scripts/psctl resources` to confirm which resources the key may touch.
5. **Housekeeping** — ensure `.psctl/` is gitignored (audit log + snapshots hold shop data).
6. Report back: shop, reachable yes/no, resources available.

## Setup (credentials)

Credentials come from the plugin's **userConfig** fields — set them once in the plugin
config form:

- `PRESTASHOP_URL` — e.g. `https://shop.example.com` (`/api` is appended automatically)
- `PRESTASHOP_TOKEN` — the webservice key, marked **sensitive** (masked, stored in the
  host keychain / credentials — never in plaintext)

They are injected as `CLAUDE_PLUGIN_OPTION_*`, which `psctl` reads automatically. For a
standalone CLI run you may instead `export PRESTASHOP_URL=… PRESTASHOP_TOKEN=…`; if neither
is set on a TTY, `psctl` prompts (hidden input). The token is never printed;
`PSCTL_DEBUG=1` masks it.

**No key yet?** Run `scripts/psctl token-help` — it prints the exact back-office
steps and a ready link, scoped to least privilege. Full guide: `references/token-setup.md`.

## Quick Reference

```bash
scripts/psctl ping                                   # verify auth + reachability
scripts/psctl resources                              # list all available API resources
scripts/psctl get products display=full limit=5
scripts/psctl get products 'filter[active]=1' 'display=[id,reference,price]' 'sort=[id_DESC]'
scripts/psctl get orders 42                          # one record by id
scripts/psctl schema products blank                  # empty XML template for creating
scripts/psctl create products -f new-product.xml     # POST (XML body or stdin)
scripts/psctl update products 7 -f patch.xml         # PUT
scripts/psctl delete products 7                      # DELETE
scripts/psctl raw GET /stock_availables              # escape hatch
scripts/psctl audit 50                               # last 50 mutations this project
```

Query params (`display`, `filter[...]`, `sort`, `limit`, `schema`) are passed verbatim
to the webservice — full syntax in `references/webservice-api.md`.

## How It Works

- Base URL normalized to end in `/api`. Responses are **XML** — PrestaShop's native,
  authoritative format (its JSON output is incomplete/unreliable for many resources, so
  this skill ignores JSON). `psctl` pretty-prints via `xmllint` when available.
- Writes take XML: fetch a template with `schema <resource> blank`, fill it, pipe/`-f` into `create`/`update`.
- `raw` passes trailing args straight to `curl` for anything not covered.

## Operating Policies

Mandatory when operating a real store — keeps bulk work safe, reviewable, reversible.
Templates: `references/operating-policies.md`.

### Batch changes (more than a few mutations)
Never fire a dozen ad-hoc commands by hand. Instead:
1. **Generate a reviewable script** — one `psctl` call per record, or a loop over a data file.
2. **Dry-run it:** `PSCTL_DRY_RUN=1 bash change.sh` — prints every mutation, sends nothing.
3. **Run for real** with `set -e` so a bad record doesn't cascade.

### Auditability (automatic — do not disable)
Every `POST`/`PUT`/`DELETE` is logged to `./.psctl/audit.log`
(`ts, method, path, HTTP code, snapshot`). Before each `PUT`/`DELETE`, `psctl`
snapshots the prior record as XML under `./.psctl/snapshots/`.
- Review: `scripts/psctl audit 50`
- **Roll back:** `scripts/psctl update <resource> <id> -f .psctl/snapshots/<file>`
- Gitignore it: `echo '.psctl/' >> .gitignore` (snapshots may hold store data).

### Reporting (after any larger job)
End with a short report: scope, counts (created / updated / deleted / failed),
notable per-record outcomes, and rollback pointers (`.psctl/audit.log` + snapshot dir).

**Format depends on where you run — this matters:**
- **Claude Desktop** (can render rich HTML artifacts): emit the report as a styled HTML
  artifact built from `assets/report-template.html` — the Anthropic / Claude look (warm
  neutral canvas, clay accent, card layout, light+dark). Use this HTML style **only** in
  Claude Desktop.
- **Claude Code / terminal / anywhere else:** plain **Markdown** (template in
  `references/operating-policies.md`). Do **not** emit the HTML style there — it renders as raw tags.

### Learning from long sessions (auto-prompt via plugin hooks)
A `Stop` hook watches how many mutations a session performed (delta in
`.psctl/audit.log` vs the `SessionStart` baseline). When it crosses
`PSCTL_OPTIMIZE_THRESHOLD` (default 10), it prompts **once** to offer the user:
analyze what this session did and **save a reusable note or script** under
`./.psctl/notes/` (named after the task) so the same work is faster next time.
Hook scripts live in the skill's `hooks/`; they are registered in the plugin's root `hooks/hooks.json`.

## Reference Files

- `references/webservice-api.md` — resources, HTTP methods, filter/display/sort/limit syntax, XML read/write format, common errors.
- `references/token-setup.md` — creating & scoping a webservice key, enabling the webservice, host gotchas.
- `references/operating-policies.md` — batch-script skeleton, dry-run workflow, rollback, report templates (HTML + Markdown).
- `assets/report-template.html` — Anthropic/Claude-styled HTML report (Claude Desktop only).

## Verify

`bash tests/selftest.sh` and `bash tests/hook_selftest.sh` run offline checks (no
network). `scripts/psctl ping` checks a live store.

## Common Mistakes

- **401/Unauthorized** — key wrong, or lacks permission on that resource/method.
- **Enable the webservice** — Advanced Parameters → Webservice → "Enable PrestaShop's webservice" = Yes.
- **404 on /api** — some hosts need URL rewriting enabled for `/api`.
- **Writes rejected** — body must be valid webservice XML; start from `schema … blank`.
- **Empty/odd JSON** — don't; PrestaShop JSON is unreliable. This skill uses XML.

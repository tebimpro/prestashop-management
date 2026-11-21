# Operating policies — batch, audit, rollback, reporting

Concrete templates for the policies in `SKILL.md`. Goal: bulk store changes
that are **reviewable before they run**, **logged while they run**, and
**reversible after they run**.

## 1. Batch changes

PrestaShop's webservice has no bulk endpoint — each record is one HTTP call.
So a "batch" is a reviewable script that loops. Write it to a file; never
improvise a dozen mutations by hand.

### Pattern A — loop over an id list / CSV

```bash
#!/usr/bin/env bash
# disable-20-products.sh — set active=0 for the ids in ids.txt
set -euo pipefail
psctl="${PSCTL:-scripts/psctl}"   # point PSCTL at the skill's scripts/psctl

while read -r id; do
  [ -n "$id" ] || continue
  # round-trip: fetch current XML, flip <active>, PUT it back
  "$psctl" raw GET "/products/$id" \
    | sed 's#<active><!\[CDATA\[1\]\]></active>#<active><![CDATA[0]]></active>#' \
    | "$psctl" update products "$id"
  echo "disabled $id"
done < ids.txt
```

### Pattern B — one explicit line per record (clearest diff to review)

```bash
#!/usr/bin/env bash
set -euo pipefail
psctl="${PSCTL:-scripts/psctl}"   # point PSCTL at the skill's scripts/psctl
"$psctl" update products 10 -f patches/10.xml
"$psctl" update products 11 -f patches/11.xml
"$psctl" delete products 99
```

### Always dry-run first

```bash
PSCTL_DRY_RUN=1 bash disable-20-products.sh   # prints every mutation, sends nothing
bash disable-20-products.sh                   # for real, stops on first error (set -e)
```

`PSCTL_DRY_RUN=1` short-circuits POST/PUT/DELETE inside `psctl` and logs
`[dry-run] METHOD url (not executed)` to stderr. GETs still run (needed to build
the bodies), but change nothing.

## 2. Audit trail (automatic)

Every mutation appends a tab-separated line to `$PSCTL_LOG_DIR/audit.log`
(default `./.psctl/audit.log`):

```
2026-11-04T10:22:31Z    PUT     products/42     HTTP=200   snapshot=.psctl/snapshots/20261104T102231Z-products_42.xml
2026-11-04T10:22:32Z    DELETE  products/99     HTTP=200   snapshot=.psctl/snapshots/20261104T102232Z-products_99.xml
```

- Review recent activity: `psctl audit 50`
- Filter: `grep DELETE .psctl/audit.log`
- Point it elsewhere (e.g. per-run dir): `PSCTL_LOG_DIR=.psctl/run-$(date +%s) bash change.sh`

**Gitignore it** — snapshots contain store data: `echo '.psctl/' >> .gitignore`.

## 3. Rollback

Before each `PUT`/`DELETE`, `psctl` saves the prior record as XML in
`.psctl/snapshots/`. To restore it:

```bash
# undo an edit or an accidental delete — re-PUT / re-create the snapshot:
psctl update products 42 -f .psctl/snapshots/20261104T102231Z-products_42.xml
```

- **Undo a `create`:** there is no prior state; reverse it by deleting the id
  the POST returned (visible in the command output and audit log).
- **Undo a `delete`:** the snapshot is the full record — re-create it with
  `psctl create <resource> -f <snapshot>` (the id may change; associations may
  need re-linking).

## 4. Report after a larger job

When a job touched more than a handful of records, finish with a short report.

**In Claude Desktop** (rich HTML artifacts): render the report as a styled HTML
artifact from `assets/report-template.html` (Anthropic/Claude look). **In a terminal /
Claude Code**: use the Markdown skeleton below. Never emit the HTML style outside Claude
Desktop — it shows up as raw tags.

Markdown skeleton:

```markdown
## PrestaShop change report — <date>
**Shop:** <PRESTASHOP_URL>   **Scope:** <what & why>

| Action  | Count | Resource  |
|---------|-------|-----------|
| updated |  18   | products  |
| deleted |   1   | products  |
| failed  |   0   | —         |

**Notable:** <ids that behaved unexpectedly, skipped records, etc.>

**Rollback:** audit `.psctl/audit.log`, snapshots in `.psctl/snapshots/`.
Restore any record with:
`psctl update <resource> <id> -f .psctl/snapshots/<file>`
```

Derive the counts straight from the log:

```bash
echo "updated: $(grep -c $'\tPUT\t'    .psctl/audit.log)"
echo "created: $(grep -c $'\tPOST\t'   .psctl/audit.log)"
echo "deleted: $(grep -c $'\tDELETE\t' .psctl/audit.log)"
echo "failed:  $(grep -Ec 'HTTP=[45][0-9][0-9]' .psctl/audit.log)"
```

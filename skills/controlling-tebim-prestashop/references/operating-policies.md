<!-- © Tebim sp. z o.o. | tebim.pro -->
# Operating policies — batch, audit, rollback, reporting

Concrete templates for the policies in `SKILL.md`. Goal: bulk store changes
that are **reviewable before they run**, **logged while they run**, and
**reversible after they run**. All mechanics (`ps_req`, `ps_mut`, `.psctl/`)
are defined in `api-calls.md`.

## 1. Batch changes

PrestaShop's webservice has no bulk endpoint — each record is one HTTP call.
So a "batch" is a reviewable script that loops. Write it to
`.psctl/work/<task>.sh`; never improvise a dozen mutations by hand.

Every batch script starts the same way:

```bash
# <task>.sh — <what & why>
set -euo pipefail
# --- paste the helpers block from api-calls.md §2 here (B, C, ps_req, ps_mut) ---
```

### Pattern A — loop over an id list / CSV (round-trip edit)

```bash
# disable the products listed in .psctl/work/ids.txt
while read -r id; do
  [ -n "$id" ] || continue
  ps_req GET "products/$id" >/dev/null
  f=".psctl/work/product-$id.xml"; cp .psctl/last.xml "$f"
  sed -i.bak 's#<active><!\[CDATA\[1\]\]></active>#<active><![CDATA[0]]></active>#' "$f"
  sed -i.bak -e '/<manufacturer_name/d' -e '/<quantity[ >]/d' "$f"   # read-only on write
  ps_mut PUT "products/$id" "$f" >/dev/null
  echo "disabled $id"
done < .psctl/work/ids.txt
```

### Pattern B — one explicit line per record (clearest diff to review)

```bash
ps_mut PUT products/10 .psctl/work/patches/10.xml
ps_mut PUT products/11 .psctl/work/patches/11.xml
ps_mut DELETE products/99
```

### Always dry-run first

```bash
PSCTL_DRY_RUN=1 bash .psctl/work/<task>.sh   # prints every mutation, sends nothing
bash .psctl/work/<task>.sh                   # for real, stops on first error (set -e)
```

With `PSCTL_DRY_RUN=1`, `ps_mut` prints `[dry-run] METHOD url (not executed)` to
stderr, sends nothing and writes no audit line. Reads (`ps_req`) still run —
they are needed to build the bodies — but change nothing. Show the dry-run
output to the user before the real run.

## 2. Audit trail (automatic)

Every `ps_mut` call appends a tab-separated line to `.psctl/audit.log` — also
when the request fails:

```
2026-11-04T10:22:31Z    PUT     products/42     HTTP=200   snapshot=.psctl/snapshots/20261104T102231Z-products_42.xml
2026-11-04T10:22:32Z    DELETE  products/99     HTTP=200   snapshot=.psctl/snapshots/20261104T102232Z-products_99.xml
2026-11-04T10:22:33Z    POST    products        HTTP=201   snapshot=-
```

- Review recent activity: `tail -n 50 .psctl/audit.log`
- Filter: `grep $'\tDELETE\t' .psctl/audit.log`
- `HTTP=000` means the request never reached the shop (network/DNS/TLS).

**Gitignore it** — snapshots contain store data (the setup block does this).

## 3. Rollback

Before each `PUT`/`DELETE`, `ps_mut` saves the prior record as XML in
`.psctl/snapshots/` under a unique name (several changes to the same record in
one second get `-1`, `-2`… suffixes, so the oldest state is never lost). The
audit line names the file. To restore:

```bash
# undo an edit — re-PUT the snapshot:
ps_mut PUT products/42 .psctl/snapshots/20261104T102231Z-products_42.xml
```

- **Undo a `create`:** there is no prior state; delete the id the POST returned
  (visible in the response and in `.psctl/last.xml`).
- **Undo a `delete`:** the snapshot is the full record — re-create it with
  `ps_mut POST <resource> <snapshot>` (the id will change; associations may
  need re-linking; drop the `<id>` element if the shop rejects it).
- `snapshot=-` on a `PUT`/`DELETE` means the record could not be read first
  (e.g. it didn't exist) — there is nothing to restore.

## 4. Report after a larger job

When a job touched more than a handful of records, finish with a short report.

**In Claude Desktop** (rich HTML artifacts): render it as a styled HTML artifact
from `report-template.md`. **In a terminal / Claude Code**: use the Markdown
skeleton below. Never emit HTML outside Claude Desktop — it shows up as raw tags.

Markdown skeleton:

```markdown
## PrestaShop change report — <date>
**Shop:** <shop URL>   **Scope:** <what & why>

| Action  | Count | Resource  |
|---------|-------|-----------|
| updated |  18   | products  |
| deleted |   1   | products  |
| failed  |   0   | —         |

**Notable:** <ids that behaved unexpectedly, skipped records, etc.>

**Rollback:** audit `.psctl/audit.log`, snapshots in `.psctl/snapshots/`.
Restore any record with:
`ps_mut PUT <resource>/<id> .psctl/snapshots/<file>`
```

Derive the counts straight from the log (limit to this job's lines with
`tail -n +<baseline+1>` if the log holds older work):

```bash
echo "updated: $(grep -c $'\tPUT\t'    .psctl/audit.log)"
echo "created: $(grep -c $'\tPOST\t'   .psctl/audit.log)"
echo "deleted: $(grep -c $'\tDELETE\t' .psctl/audit.log)"
echo "failed:  $(grep -Ec 'HTTP=(000|[45][0-9][0-9])' .psctl/audit.log)"
```

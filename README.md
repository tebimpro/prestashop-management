<!-- © Tebim sp. z o.o. | tebim.pro -->
# PrestaShop Management for AI Agents

**Let your AI agent run your PrestaShop store — safely.**
A plugin + skill by [Tebim](https://tebim.pro) that lets Claude (and other skill-aware agents) read and modify a PrestaShop shop through its Webservice API: products, orders, customers, stock, prices, categories and more — with dry-runs, an audit log and one-command rollback.

🇵🇱 [Wersja polska → README.pl.md](README.pl.md)

---

## Why

Clicking through the back office for bulk work is slow and error-prone. Letting an agent loose on a live store is scary. This plugin teaches the agent a small, auditable way of calling the API (`curl` + two helpers, `ps_req` and `ps_mut`) and strict operating rules:

- **Dry-run first** — every batch change is a reviewable script, previewed with `PSCTL_DRY_RUN=1` before anything is sent.
- **Audit log** — every `POST` / `PUT` / `DELETE` is logged to `./.psctl/audit.log`.
- **Rollback** — before each `PUT` / `DELETE` the previous record is snapshotted as XML; restoring it is one command.
- **Least privilege** — guided Webservice key creation with only the permissions you need. The key is never printed and never put on a command line (it lives in a `chmod 600` curl config).
- **Nothing to install** — the plugin is pure Markdown + JSON; the agent only needs `bash` + `curl` (optional `xmllint`). macOS and Linux.

Works with PrestaShop **1.7, 8.x and 9.x** (legacy Webservice API).

## Install

### Claude Code / Cowork

```text
/plugin marketplace add tebimpro/prestashop-management
/plugin install tebim-prestashop-connector@tebim
```

On install you'll be asked for:

| Field | Example |
|-------|---------|
| `PRESTASHOP_URL` | `https://shop.example.com` (`/api` is added automatically) |
| `PRESTASHOP_TOKEN` | your Webservice key — stored as a **sensitive** value |

Then run `/tebim-prestashop-connect` to verify the connection and the key's permissions.

### Other agents (skill only)

The skill in [`skills/controlling-tebim-prestashop/`](skills/controlling-tebim-prestashop/) follows the Agent Skills format (`SKILL.md` + references, Markdown only). Copy that folder into your agent's skills directory and provide credentials as environment variables:

```bash
export PRESTASHOP_URL=https://shop.example.com
export PRESTASHOP_TOKEN=YOUR_WEBSERVICE_KEY
```

## Usage

Just ask the agent in plain language, e.g.:

> *"Show me the 10 most expensive active products."*
> *"Disable all products from category 12 that have zero stock — dry-run first."*
> *"Roll back the price change you made to product 42."*

Slash commands:

| Command | What it does |
|---------|--------------|
| `/tebim-prestashop-connect [shop-url]` | Onboarding: connect, verify auth, list accessible resources |
| `/tebim-control-prestashop <task>` | Run a store task following the skill's safety rules |

> The bundled commands currently talk to the user in **Polish**. The skill itself is language-neutral and answers in the user's language.

### How the agent calls the API

The skill's [`references/api-calls.md`](skills/controlling-tebim-prestashop/references/api-calls.md) defines a one-time session setup and two shell helpers the agent pastes inline:

```bash
ps_req GET "" >/dev/null && echo OK            # verify auth + reachability
ps_req GET products -G --data-urlencode 'filter[active]=1' \
  --data-urlencode 'display=[id,reference,price]' --data-urlencode limit=10
ps_req GET orders/42                           # one record
ps_mut PUT products/42 .psctl/work/p42.xml     # PUT (snapshot + audit line first)
ps_mut DELETE products/42                      # DELETE (snapshot + audit line first)
tail -n 50 .psctl/audit.log                    # last 50 mutations
PSCTL_DRY_RUN=1 bash .psctl/work/change.sh     # preview a batch, send nothing
```

Full API notes: [`references/webservice-api.md`](skills/controlling-tebim-prestashop/references/webservice-api.md) · Key setup: [`references/token-setup.md`](skills/controlling-tebim-prestashop/references/token-setup.md) · Batch/rollback/reporting: [`references/operating-policies.md`](skills/controlling-tebim-prestashop/references/operating-policies.md)

## Creating a Webservice key

1. Back office → **Advanced Parameters → Webservice**.
2. **Enable PrestaShop's webservice** = Yes.
3. **Add new webservice key** → Generate.
4. Tick **only** the resources/methods you need (read-only = `GET` only).
5. Save and paste the key into the plugin config.

## Repository layout

```text
.claude-plugin/
  plugin.json            # plugin manifest (userConfig: URL + sensitive token)
  marketplace.json       # lets this repo act as a Claude Code marketplace
commands/                # /tebim-prestashop-connect, /tebim-control-prestashop
skills/controlling-tebim-prestashop/
  SKILL.md
  references/
    api-calls.md         # setup + ps_req/ps_mut helpers + every operation
    webservice-api.md    # API syntax: filters, display, XML format, errors
    token-setup.md       # creating & scoping a Webservice key
    operating-policies.md# batch, dry-run, audit, rollback, reports
    report-template.md   # HTML report template (Claude Desktop)
```

The plugin contains only Markdown and JSON — no scripts, binaries or hooks.

## Development

```bash
claude plugin validate .
```

CI validates the JSON manifests and checks that the repo holds only allowed file types. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

Never commit your Webservice key or the `.psctl/` directory (snapshots contain store data). Report vulnerabilities privately — see [SECURITY.md](SECURITY.md).

## Out of scope

The PrestaShop 9 OAuth2 *Admin API*, theme development and direct database edits.

## About Tebim

[Tebim sp. z o.o.](https://tebim.pro) is a PrestaShop agency from Kalisz, Poland — implementations, UX/UI, and ERP/WMS/PIM integrations for B2B and B2C e-commerce. Need help with your store? **contact@tebim.pro**

## License

[BSD 2-Clause](LICENSE) © Tebim sp. z o.o.

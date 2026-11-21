<!-- © Tebim sp. z o.o. | tebim.pro -->
# PrestaShop Management for AI Agents

**Let your AI agent run your PrestaShop store — safely.**
A plugin + skill by [Tebim](https://tebim.pro) that lets Claude (and other skill-aware agents) read and modify a PrestaShop shop through its Webservice API: products, orders, customers, stock, prices, categories and more — with dry-runs, an audit log and one-command rollback.

🇵🇱 [Wersja polska → README.pl.md](README.pl.md)

---

## Why

Clicking through the back office for bulk work is slow and error-prone. Letting an agent loose on a live store is scary. This plugin gives the agent a small, auditable CLI (`psctl`) and strict operating rules:

- **Dry-run first** — every batch change is a reviewable script, previewed with `PSCTL_DRY_RUN=1` before anything is sent.
- **Audit log** — every `POST` / `PUT` / `DELETE` is logged to `./.psctl/audit.log`.
- **Rollback** — before each `PUT` / `DELETE` the previous record is snapshotted as XML; restoring it is one command.
- **Least privilege** — guided Webservice key creation with only the permissions you need. The key is never printed.
- **Zero dependencies** — pure bash + `curl` (optional `xmllint`). macOS (bash 3.2) and Linux.

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

The skill in [`skills/controlling-tebim-prestashop/`](skills/controlling-tebim-prestashop/) follows the Agent Skills format (`SKILL.md` + scripts + references). Copy that folder into your agent's skills directory and provide credentials as environment variables:

```bash
export PRESTASHOP_URL=https://shop.example.com
export PRESTASHOP_TOKEN=YOUR_WEBSERVICE_KEY
```

### Standalone CLI

```bash
skills/controlling-tebim-prestashop/scripts/psctl ping
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

### `psctl` quick reference

```bash
psctl ping                                     # verify auth + reachability
psctl resources                                # resources your key can access
psctl get products 'filter[active]=1' 'display=[id,reference,price]' 'sort=[price_DESC]' limit=10
psctl get orders 42                            # one record
psctl schema products blank > product.xml      # XML template for writes
psctl create products -f product.xml           # POST
psctl update products 42 -f product.xml        # PUT (snapshot taken first)
psctl delete products 42                       # DELETE (snapshot taken first)
psctl audit 50                                 # last 50 mutations
PSCTL_DRY_RUN=1 bash change.sh                 # preview a batch, send nothing
```

Full API notes: [`references/webservice-api.md`](skills/controlling-tebim-prestashop/references/webservice-api.md) · Key setup: [`references/token-setup.md`](skills/controlling-tebim-prestashop/references/token-setup.md) · Batch/rollback/reporting: [`references/operating-policies.md`](skills/controlling-tebim-prestashop/references/operating-policies.md)

## Creating a Webservice key

1. Back office → **Advanced Parameters → Webservice**.
2. **Enable PrestaShop's webservice** = Yes.
3. **Add new webservice key** → Generate.
4. Tick **only** the resources/methods you need (read-only = `GET` only).
5. Save and paste the key into the plugin config.

`psctl token-help` prints these steps with your shop URL filled in.

## Repository layout

```text
.claude-plugin/
  plugin.json            # plugin manifest (userConfig: URL + sensitive token)
  marketplace.json       # lets this repo act as a Claude Code marketplace
commands/                # /tebim-prestashop-connect, /tebim-control-prestashop
hooks/hooks.json         # SessionStart + Stop hooks
skills/controlling-tebim-prestashop/
  SKILL.md
  scripts/psctl          # the CLI
  references/            # API, key setup, operating policies
  assets/                # HTML report template
  hooks/                 # hook scripts
  tests/                 # offline self-tests
```

## Development

```bash
bash skills/controlling-tebim-prestashop/tests/selftest.sh       # psctl logic, offline
bash skills/controlling-tebim-prestashop/tests/hook_selftest.sh  # hooks, offline
shellcheck -S warning skills/controlling-tebim-prestashop/{scripts/psctl,hooks/*.sh,tests/*.sh}
```

CI runs the same checks on Linux and macOS. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

Never commit your Webservice key or the `.psctl/` directory (snapshots contain store data). Report vulnerabilities privately — see [SECURITY.md](SECURITY.md).

## Out of scope

The PrestaShop 9 OAuth2 *Admin API*, theme development and direct database edits.

## About Tebim

[Tebim sp. z o.o.](https://tebim.pro) is a PrestaShop agency from Kalisz, Poland — implementations, UX/UI, and ERP/WMS/PIM integrations for B2B and B2C e-commerce. Need help with your store? **contact@tebim.pro**

## License

[BSD 2-Clause](LICENSE) © Tebim sp. z o.o.

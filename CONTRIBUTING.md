<!-- © Tebim sp. z o.o. | tebim.pro -->
# Contributing

Thanks for helping improve PrestaShop Management for AI Agents!

## Ground rules

- **Keep `psctl` dependency-free**: bash + `curl` only (`xmllint` optional). It must run on macOS's bash 3.2 — no associative arrays, `mapfile`, `${var,,}` etc.
- **Never weaken the safety model**: audit log, snapshots before `PUT`/`DELETE`, dry-run and token masking stay on by default.
- **No secrets or store data** in issues, PRs or test fixtures.
- New files carry the header `© Tebim sp. z o.o. | tebim.pro`.

## Before opening a PR

```bash
bash skills/controlling-tebim-prestashop/tests/selftest.sh
shellcheck -S warning skills/controlling-tebim-prestashop/{scripts/psctl,tests/*.sh}
```

Add a self-test for any new pure logic in `psctl`, and an entry under *Unreleased* in [CHANGELOG.md](CHANGELOG.md).

## Releasing (maintainers)

1. Bump `version` in `.claude-plugin/plugin.json`.
2. Move *Unreleased* entries in `CHANGELOG.md` under the new version.
3. Tag `vX.Y.Z` and create a GitHub release.

## Questions

Open an issue or write to contact@tebim.pro.

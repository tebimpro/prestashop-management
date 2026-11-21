<!-- © Tebim sp. z o.o. | tebim.pro -->
# Contributing

Thanks for helping improve PrestaShop Management for AI Agents!

## Ground rules

- **Markdown and JSON only.** The plugin ships no scripts, binaries, hooks or HTML — the agent runs the documented `curl` snippets itself. Don't add files that start with `#!`, package-manager files, or images other than the plugin icon (PNG).
- **Keep snippets portable**: bash 3.2 (macOS default) + `curl` only (`xmllint` optional) — no associative arrays, `mapfile`, `${var,,}`, GNU-only `sed -i` (use `sed -i.bak`).
- **Never weaken the safety model**: every mutation via `ps_mut` (audit log, snapshot before `PUT`/`DELETE`, dry-run), key only in `.psctl/curlrc`, never printed.
- **No secrets or store data** in issues, PRs or test fixtures.
- New files carry the header `© Tebim sp. z o.o. | tebim.pro`.

## Before opening a PR

```bash
claude plugin validate .
```

If you change the helpers in `references/api-calls.md`, test them against a real (staging) shop or a local mock: read, `PUT` + snapshot, `DELETE`, dry-run, a failing request. Add an entry under *Unreleased* in [CHANGELOG.md](CHANGELOG.md).

## Releasing (maintainers)

1. Bump `version` in `.claude-plugin/plugin.json`.
2. Move *Unreleased* entries in `CHANGELOG.md` under the new version.
3. Tag `vX.Y.Z` and create a GitHub release.

## Questions

Open an issue or write to contact@tebim.pro.

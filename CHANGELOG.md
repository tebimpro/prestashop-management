<!-- © Tebim sp. z o.o. | tebim.pro -->
# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [0.4.0] — 2026-11-21

First public release. The plugin now contains only Markdown and JSON, as required by the Claude plugin directory for non-verified organizations.

### Changed
- **`psctl` CLI removed.** Its behaviour moved into the skill as a documented `curl` playbook (`references/api-calls.md`): one-time session setup plus two inline helpers — `ps_req` (reads) and `ps_mut` (writes with audit log, pre-change snapshot and `PSCTL_DRY_RUN=1`). Same `.psctl/` layout, same audit-log format, same rollback flow.
- The Webservice key is stored in `.psctl/curlrc` (`chmod 600`) and passed with `curl -K` — it no longer appears on the command line or in the process list.
- No plugin hooks. The "save a reusable note after a long session" offer is now an instruction in `SKILL.md` (10+ mutations).
- HTML report template moved to `references/report-template.md`.
- Slash commands and references updated to the new helpers.

### Fixed
- Snapshots of several changes to the same record within one second no longer overwrite each other (the oldest pre-change state was lost before).
- Snapshots are no longer saved from error responses (`curl -f`).
- Query values are URL-encoded by curl (`--data-urlencode`), so UTF-8 (e.g. Polish characters) and `%` wildcards work.
- Documented read-only product fields to drop before `PUT` (`manufacturer_name`, `quantity`).

### Added
- `marketplace.json` so the repository can be added as a Claude Code marketplace.
- README (EN) + README.pl.md, CONTRIBUTING, SECURITY, CI.

## [0.3.0] — 2026-11-04

Internal version (not published): `psctl` CLI, hooks, slash commands.

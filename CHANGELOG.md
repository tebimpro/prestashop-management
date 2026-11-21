<!-- © Tebim sp. z o.o. | tebim.pro -->
# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [0.3.0] — 2026-11-21

First public release.

### Added
- `psctl` CLI for the PrestaShop Webservice API: `ping`, `resources`, `get`, `schema`, `create`, `update`, `delete`, `raw`, `audit`, `token-help`.
- Automatic audit log and pre-change XML snapshots for rollback.
- `PSCTL_DRY_RUN=1` preview mode for batch changes.
- Plugin `userConfig` for shop URL and a sensitive Webservice key.
- Slash commands `/tebim-prestashop-connect` and `/tebim-control-prestashop`.
- SessionStart/Stop hooks offering to save reusable notes after long sessions.
- `marketplace.json` so the repository can be added as a Claude Code marketplace.
- CI (shellcheck + offline self-tests on Linux and macOS).

### Fixed
- `urlencode` now encodes UTF-8 correctly (e.g. Polish characters in filter values).
- Documentation: correct hooks manifest path; `raw` usage with query parameters.

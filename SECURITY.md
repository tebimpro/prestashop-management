<!-- © Tebim sp. z o.o. | tebim.pro -->
# Security Policy

## Reporting a vulnerability

Please **do not** open a public issue. Email **contact@tebim.pro** with the subject `SECURITY: prestashop-management` and include steps to reproduce. We aim to respond within 5 business days.

## Using the plugin safely

- **Least privilege**: give the Webservice key only the resources and HTTP methods the task needs; use a read-only key for reporting.
- **Separate keys** per agent / environment, and rotate them when people or tools change.
- **Prefer staging** for new batch scripts; always dry-run (`PSCTL_DRY_RUN=1`) against production first.
- **Keep `.psctl/` out of git** — the audit log and snapshots contain store data (possibly personal data of customers; mind GDPR).
- **HTTPS only** — the key travels as HTTP Basic Auth.
- `psctl` never prints the key (`PSCTL_DEBUG=1` masks it). Note that it is passed to `curl` as a command-line argument, so on shared multi-user machines it may be visible in the process list — run it on a machine you control.

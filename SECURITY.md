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
- The key is written once into `.psctl/curlrc` (`chmod 600`) and passed to curl with `-K`, so it never appears on a command line, in the process list or in the agent transcript. The skill forbids `curl -v` / `--trace`, which would print the auth header.

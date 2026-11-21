# Creating & providing a PrestaShop Webservice key

A "token" for the legacy API is a **webservice key** created in the back
office. It is used as the HTTP Basic Auth username (empty password).

## Create the key

1. **Log into the back office.** Your admin folder has an obfuscated name
   (e.g. `/admin1a2b3c/`). There is no deep link to the webservice page
   without an active session token, so navigate from the menu:
   - Direct link to start: `https://<shop>/admin*/` (log in there)
2. Go to **Advanced Parameters → Webservice**.
3. Set **"Enable PrestaShop's webservice" = Yes** and save.
   (If the shop is behind a proxy/CDN, also "Enable for SSL" as needed.)
4. Click **Add new webservice key → Generate** (or paste your own 32-char key).
5. Set **Key description** (e.g. "psctl automation").
6. **Permissions:** tick **only** the resources and methods you actually need.
   Columns are View (GET), Modify (PUT), Add (POST), Delete, Fast view / HEAD.
   - Read-only automation → GET on the needed resources only.
   - Full CRUD on products → GET/POST/PUT/DELETE on `products`,
     `stock_availables`, `images`, `categories`, `specific_prices` as needed.
   Least privilege limits blast radius if the key leaks.
7. **Save.** Copy the key.

`psctl token-help` prints these steps pre-filled with your shop URL.

## Provide the key to psctl

The key lives in the plugin's **userConfig** fields (set in the plugin config form):

- `PRESTASHOP_URL` — the shop URL
- `PRESTASHOP_TOKEN` — the key, marked **`sensitive`** → masked in the form and stored in
  the host keychain / credentials, never in plaintext settings.

They are injected into `psctl` as `CLAUDE_PLUGIN_OPTION_PRESTASHOP_URL` /
`CLAUDE_PLUGIN_OPTION_PRESTASHOP_TOKEN`, which it reads automatically.

**Standalone CLI (no plugin host):**
```bash
export PRESTASHOP_URL=https://shop.example.com
export PRESTASHOP_TOKEN=YOUR_KEY
psctl ping
```

**Interactive prompt (last resort):** if nothing is set on a TTY, `psctl` prompts with
hidden input (`read -s`). The key is never echoed, never logged; `PSCTL_DEBUG=1` masks it.

## Host gotchas

- **`/api` returns 404:** the host must allow URL rewriting for `/api`. On
  Apache ensure `mod_rewrite` + the shop's `.htaccess` are active; on nginx the
  webservice rewrite rules must be present in the vhost.
- **401 even with a correct key:** the webservice is probably still disabled
  (step 3), or SSL is required and you hit `http://`.
- **403 on a specific resource:** the key is missing that resource/method in
  its permission grid.
- **Rotating a key:** delete/regenerate in the same grid; update the plugin's `PRESTASHOP_TOKEN` config field.

## Verify

```bash
psctl ping          # OK -> authenticated and reachable
psctl resources     # lists every resource this key may touch
```

<!-- © Tebim sp. z o.o. | tebim.pro -->
# PrestaShop Webservice API — reference

The legacy Webservice is a REST API exposed at `https://<shop>/api/`. It is
available in PrestaShop 1.6, 1.7, 8.x and (still) 9.x. This file documents the
subset you need to drive a store with the `ps_req` / `ps_mut` helpers from
`api-calls.md`.

## Authentication

The webservice **key** is the HTTP Basic Auth **username**; the password is
empty:

```bash
curl -u "YOUR_KEY:" https://shop.example.com/api/
```

The helpers do this via `-K .psctl/curlrc` (never put the key on the command line). Keys are created and permission-scoped per resource
and per HTTP method in the back office (see `token-setup.md`).

## Endpoints & HTTP methods

| Method | Meaning | helper |
|--------|---------|-------|
| `GET`    | read a list or a single record | `ps_req GET` |
| `POST`   | create a record (XML body)      | `ps_mut POST` |
| `PUT`    | update a record (XML body)      | `ps_mut PUT` |
| `DELETE` | delete a record                 | `ps_mut DELETE` |
| `HEAD`   | headers only (rarely needed)    | `curl -K .psctl/curlrc -I …` |

- `GET /api/` → the list of every resource the key may access.
- `GET /api/<resource>` → list (by default only ids).
- `GET /api/<resource>/<id>` → one full record.

## Output format

Responses are **XML** — the webservice's native format and the authoritative one.
PrestaShop's JSON output (`output_format=JSON`) is incomplete/unreliable for many
resources, so this skill standardises on XML: it round-trips straight into
writes and into rollback snapshots. `ps_req` pretty-prints XML with
`xmllint --format` when available. Need JSON for a one-off read?
`ps_req GET <path> -G --data-urlencode output_format=JSON`.

## Reading: display, filter, sort, limit

These are query params: `ps_req GET <resource> -G --data-urlencode 'key=value' …`
(the key is sent raw, the value URL-encoded — UTF-8 included).

### display — which fields come back
- `display=full` — all fields.
- `display=[id,reference,price]` — only these fields.
- (default, omitted) — only `id`.

### filter[field] — narrow the list
- Exact: `filter[reference]=DEMO_5`
- OR set: `filter[id]=[1|5|9]`
- Range: `filter[id]=[1,10]` (inclusive interval)
- Wildcard (`LIKE`): `filter[name]=[appl]%25` → `%25` is an encoded `%`.
  With `--data-urlencode 'filter[name]=[appl]%'` curl encodes the `%` for you.
- Begins/ends: `filter[name]=[appl]%` / `filter[name]=%[ple]`
- Combine multiple `filter[...]` params to AND them.

### sort
- `sort=[id_DESC]`, `sort=[name_ASC]`
- Multiple: `sort=[name_ASC,id_DESC]`

### limit — pagination
- `limit=5` → first 5.
- `limit=10,5` → offset 10, count 5.

### date filtering
- Add `date=1` and use `filter[date_add]=[2024-01-01,2024-12-31]`.

### Examples
```bash
ps_req GET products -G --data-urlencode 'filter[active]=1' \
  --data-urlencode 'display=[id,reference,price]' --data-urlencode 'sort=[price_DESC]' --data-urlencode limit=10
ps_req GET orders -G --data-urlencode 'filter[current_state]=3' --data-urlencode display=full
ps_req GET customers -G --data-urlencode 'filter[email]=%@gmail.com' --data-urlencode 'display=[id,email,firstname]'
ps_req GET stock_availables -G --data-urlencode 'filter[id_product]=42'
```

## Writing: create & update (XML)

Writes use the webservice **XML** format, not JSON. Workflow:

1. Get a blank template:
   ```bash
   ps_req GET products -G --data-urlencode schema=blank > .psctl/work/product.xml   # or schema=synopsis (documented)
   ```
2. Edit `product.xml` — keep only the fields you are setting; drop read-only
   ones the API rejects (ids on create, computed fields). Keep the
   `<prestashop>…<product>…</product></prestashop>` envelope.
3. Send it:
   ```bash
   ps_mut POST products .psctl/work/product.xml         # POST -> returns the created record (with new id)
   ps_mut PUT products/42 .psctl/work/product.xml       # PUT  -> full record replace; include fields you keep
   ```

`PUT` replaces the resource — fetch the current record, change fields, send it
back (round-trip) to avoid wiping values. Multilang fields look like:

```xml
<name>
  <language id="1"><![CDATA[Nazwa PL]]></language>
  <language id="2"><![CDATA[Name EN]]></language>
</name>
```

Associations (categories, images, combinations, stock) live under
`<associations>` in the record — read one full record (`get products 1
display=full`) to see the exact shape before writing.

## Common resources

`products`, `categories`, `combinations`, `product_features`,
`product_options` (+ `product_option_values`), `stock_availables`,
`specific_prices`, `manufacturers`, `suppliers`, `tags`, `images`,
`orders`, `order_details`, `order_histories`, `order_states`, `order_carriers`,
`carts`, `customers`, `addresses`, `groups`,
`carriers`, `zones`, `countries`, `states`, `currencies`, `languages`,
`taxes`, `tax_rules`, `tax_rule_groups`, `price_rules` (cart rules),
`stores`, `shops`, `shop_groups`, `shop_urls`, `configurations`,
`employees`, `customer_threads`, `customer_messages`, `search`.

Full live list for your shop: `ps_req GET ""`.

## Images

Images are a special binary sub-resource, e.g.
`GET /api/images/products/<id_product>` lists image ids, and you upload with a
multipart `POST`:

```bash
ps_mut POST images/products/42 "" -F 'image=@photo.jpg'
```

## Errors you will meet

| HTTP | Cause | Fix |
|------|-------|-----|
| 401  | bad key, or disabled webservice | check key + "Enable webservice" |
| 403  | key lacks permission on resource/method | grant it in back office |
| 404  | wrong resource/id, or `/api` not routed by host | check URL rewrite |
| 400  | malformed XML / bad field on write | start from `schema=blank` |
| 500  | invalid value, failed validation | read the XML error body (shown by the helpers) |

On 4xx/5xx the helpers print the response body (PrestaShop returns a descriptive
`<errors>` block) to stderr before failing.

## Notes

- Multistore: target a shop with `id_shop=<n>` / `id_group_shop=<n>` query
  params (e.g. `ps_req GET products -G --data-urlencode id_shop=2 --data-urlencode display=full`).
- The webservice does **not** cover everything the back office does; some
  actions (e.g. launching certain processes) have no resource. Use the
  back office or a module for those.

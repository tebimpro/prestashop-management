<!-- © Tebim sp. z o.o. | tebim.pro -->
# PrestaShop Management dla agentów AI

**Pozwól agentowi AI zarządzać sklepem PrestaShop — bezpiecznie.**
Plugin + skill od [Tebim](https://tebim.pro), dzięki któremu Claude (i inni agenci obsługujący skille) czyta i modyfikuje dane sklepu przez Webservice API: produkty, zamówienia, klientów, stany, ceny, kategorie — z dry-runem, logiem audytu i rollbackiem jedną komendą.

🇬🇧 [English version → README.md](README.md)

## Co dostajesz

- **Najpierw dry-run** — każda zmiana masowa to skrypt do przejrzenia, uruchamiany najpierw z `PSCTL_DRY_RUN=1`.
- **Log audytu** — każdy `POST` / `PUT` / `DELETE` trafia do `./.psctl/audit.log`.
- **Rollback** — przed każdym `PUT` / `DELETE` zapisywany jest snapshot rekordu (XML).
- **Least privilege** — prowadzenie krok po kroku przy tworzeniu klucza Webservice; klucz nigdy nie jest wypisywany.
- **Zero zależności** — bash + `curl` (opcjonalnie `xmllint`). macOS i Linux.

Obsługuje PrestaShop **1.7, 8.x i 9.x** (legacy Webservice API).

## Instalacja (Claude Code / Cowork)

```text
/plugin marketplace add tebimpro/prestashop-management
/plugin install tebim-prestashop-connector@tebim
```

Podczas instalacji podajesz `PRESTASHOP_URL` (np. `https://sklep.pl`) i `PRESTASHOP_TOKEN` (klucz Webservice — przechowywany jako wartość poufna). Następnie uruchom `/tebim-prestashop-connect`, żeby zweryfikować połączenie i uprawnienia klucza.

Inne agenty: skopiuj katalog `skills/controlling-tebim-prestashop/` do katalogu skilli swojego agenta i ustaw zmienne `PRESTASHOP_URL` / `PRESTASHOP_TOKEN`.

## Użycie

Po prostu poproś agenta, np.:

> *„Pokaż 10 najdroższych aktywnych produktów.”*
> *„Wyłącz produkty z kategorii 12 z zerowym stanem — najpierw dry-run.”*
> *„Cofnij zmianę ceny produktu 42.”*

| Komenda | Opis |
|---------|------|
| `/tebim-prestashop-connect [adres-sklepu]` | Onboarding: połączenie, weryfikacja klucza, lista dostępnych zasobów |
| `/tebim-control-prestashop <zadanie>` | Realizacja zadania w sklepie zgodnie z regułami bezpieczeństwa skilla |

Szczegóły (`psctl`, API, tworzenie klucza, polityki batch/rollback) — w [README.md](README.md) i katalogu `references/`.

## Bezpieczeństwo

Nie commituj klucza Webservice ani katalogu `.psctl/` (snapshoty zawierają dane sklepu). Podatności zgłaszaj prywatnie — [SECURITY.md](SECURITY.md).

## O nas

[Tebim sp. z o.o.](https://tebim.pro) — agencja PrestaShop z Kalisza: wdrożenia, UX/UI, integracje ERP/WMS/PIM dla e-commerce B2B i B2C. Potrzebujesz pomocy ze sklepem? **contact@tebim.pro**

Licencja: [BSD 2-Clause](LICENSE) © Tebim sp. z o.o.

---
description: Onboarding — podłącz sesję do sklepu PrestaShop (URL + klucz Webservice), zweryfikuj połączenie i zakres uprawnień.
argument-hint:
- adres sklepu lub nic
---

Użyj skilla **`controlling-tebim-prestashop`** (plugin `tebim-prestashop-connector`),
aby podłączyć tę sesję do sklepu PrestaShop przez legacy Webservice API.

Wejście (opcjonalne): **$ARGUMENTS** (adres sklepu).

Przeprowadź procedurę onboarding ze skilla (sekcja „Onboarding a shop"):

1. Ustal adres sklepu — jeśli nie ma go w `$ARGUMENTS`, zapytaj.
2. Klucz Webservice: jeśli użytkownik go nie ma, pokieruj przez `scripts/psctl token-help`
   (Advanced Parameters → Webservice → włącz + dodaj klucz, uprawnienia least-privilege).
   Zbierz go bezpiecznie — przez env lub `.env` (`chmod 600`). **Nigdy** nie wypisuj tokenu
   ani nie commituj go.
3. `scripts/psctl ping` — weryfikacja auth + dostępności.
4. `scripts/psctl resources` — sprawdź, do których zasobów klucz ma dostęp.
5. Zadbaj, by `.psctl/` był w `.gitignore` (log audytu + snapshoty zawierają dane sklepu).
6. Zdaj krótki raport: sklep, osiągalny tak/nie, dostępne zasoby.

Rozmawiaj po polsku.

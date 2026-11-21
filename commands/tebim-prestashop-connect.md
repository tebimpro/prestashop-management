---
description: Onboarding — podłącz sesję do sklepu PrestaShop (URL + klucz Webservice), zweryfikuj połączenie i zakres uprawnień.
argument-hint:
- adres sklepu lub nic
---

<!-- © Tebim sp. z o.o. | tebim.pro -->

Użyj skilla **`controlling-tebim-prestashop`** (plugin `tebim-prestashop-connector`),
aby podłączyć tę sesję do sklepu PrestaShop przez legacy Webservice API.

Wejście (opcjonalne): **$ARGUMENTS** (adres sklepu).

Przeprowadź procedurę onboarding ze skilla (sekcja „Onboarding a shop"), korzystając
z `references/api-calls.md`:

1. Ustal adres sklepu — z konfiguracji pluginu, zmiennych środowiskowych lub `$ARGUMENTS`;
   jeśli go nie ma, zapytaj.
2. Klucz Webservice — z konfiguracji pluginu (`PRESTASHOP_TOKEN`) lub env. Jeśli użytkownik
   go nie ma, pokieruj go krokami z `references/token-setup.md` (Advanced Parameters →
   Webservice → włącz + dodaj klucz, uprawnienia least-privilege). **Nie proś** o wklejenie
   klucza do czatu, **nigdy** go nie wypisuj (najwyżej maska `abcd****yz`) ani nie commituj.
3. Uruchom blok konfiguracji sesji (`api-calls.md` §1) — zapisze `.psctl/base`,
   `.psctl/curlrc` (`chmod 600`) i doda `.psctl/` do `.gitignore`.
4. Ping (`ps_req GET "" >/dev/null`) — weryfikacja auth + dostępności.
5. Lista zasobów (`ps_req GET ""`) — sprawdź, do których zasobów klucz ma dostęp.
6. Zdaj krótki raport: sklep, osiągalny tak/nie, dostępne zasoby.

Rozmawiaj po polsku.

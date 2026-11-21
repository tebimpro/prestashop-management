---
description: Steruj sklepem PrestaShop przez Webservice API (odczyt, zmiany, batch, rollback).
argument-hint:
- krótki opis lub input
---

<!-- © Tebim sp. z o.o. | tebim.pro -->

Użyj skilla **`controlling-tebim-prestashop`** (plugin `tebim-prestashop-connector`), aby zrealizować cel skilla controlling-tebim-prestashop.

Wejście: **$ARGUMENTS**

Trzymaj się reguł skilla — najpierw brainstorm, potem realizacja, na końcu weryfikacja.
Każda zmiana w sklepie idzie przez `ps_mut` (log audytu + snapshot), zmiany masowe najpierw jako dry-run.
Rozmawiaj z użytkownikiem po polsku.

Jeśli `$ARGUMENTS` jest puste — zapytaj, co dokładnie chcesz zrobić i po co.

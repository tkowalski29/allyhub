# Command: AGENT_STRICT
# Description: Orkiestruje subagentów do kompleksowej realizacji zadania – od analizy, przez implementację , po pełną weryfikację, samo-naprawę i finalizację.
# Arguments:
#   $TASK_ID (wymagane) – katalog .spec/$TASK_ID/ z plikami task.md i memory.md
# Output: Zrealizowane i zweryfikowane zadanie + zaktualizowana historia i artefakty gotowe do merge.

{PATH_TO_REPLACE} wskazuje na `.spec/$TASK_ID/`.

# REGUŁY ORKIESTRACJI SUBAGENTÓW
- Każde wywołanie subagenta musi być JAWNE, w formie:  
  **Use the `<agent-name>` subagent to …**
- Stosuj zasadę least-privilege; nie podnoś narzędzi ponad mapę ról.
- Jeśli którykolwiek krok zawiedzie, przejdź do pętli samo-naprawy (max 3 próby) zgodnie z sekcją „AUTO-FIX”.

---

## FAZA 1: Analiza i planowanie
1) Odczytaj wejścia:
   - Przeczytaj `{PATH_TO_REPLACE}/task.md`.
   - Jeśli istnieje: `{PATH_TO_REPLACE}/memory.md` (brak = pierwsze uruchomienie).
2) Zbierz i zweryfikuj zasoby:
   - **Use the `anl-asset-locator` subagent** to wykryć/zwalidować pliki (Figma, obrazy, linki) w `{PATH_TO_REPLACE}/`.
3) Jeśli w `task.md` występuje Figma:
   - **Use the `anl-figma-spec` subagent** to wyprowadzić spec UI (typografia/siatki/stany/ARIA).
4) Jeśli w `task.md` podano stronę referencyjną:
   - **Use the `anl-refsite-auditor` subagent** to spisać wzorce UI/UX i priorytety.
5) Kryteria akceptacji i plan:
   - **Use the `anl-acceptance-keeper` subagent** to doprecyzować AC i szkic planu testów.
6) Rozwiązanie i architektura:
   - **Use the `anl-solution-architect` subagent** to zaproponować podejście (KISS) + biblioteki.
7) (Warunkowo – gdy `task.md` opisuje EPIC a nie pojedynczy task):
   - **Use the `anl-epic-slicer` subagent** to wygenerować taski z szablonu i zapisać je do `{PATH_TO_REPLACE}/new_tasks_to_create.json` jako listę obiektów do utworzenia przez API.  
     Po tym kroku jeśli zadanie jest wyłącznie epikiem – zakończ z outputem pliku `new_tasks_to_create.json`.
8) Performance i Security Analysis:
   - **Use the `anl-performance-auditor` subagent** jeśli task affects database, cache, lub API performance
   - Measure baseline metrics dla later comparison
   - Document performance requirements i constraints

Wynik fazy 1: plan działania (kroki), decyzje arch., zaktualizowane AC, opcjonalny `new_tasks_to_create.json`.

---

## FAZA 2: Wykonanie
**Stack technologiczny:** Mapowanie:
- figma → **exe-component-stitcher**
- angular → **exe-maker-angular**

1) Implementacja z TDD:
   - **Use the `exe-tdd-driver` subagent** to poprowadzić pętlę *Red → Green → Refactor* (małe iteracje).
   - **Use the `exe-test-writer` subagent** w tandemie (pisze testy pod AC).
   - Następnie **Use the `exe-maker-<stack>` subagent** to minimalnie implementować funkcję do zielonego testu.
2) (UI na podstawie zasobów):
   - Jeśli są makiety/obrazy: **Use the `exe-component-stitcher` subagent**.
3) Integracja i dane:
   - **Use the `exe-integration-writer` subagent** (API/dane/routing/kontrakty).
   - **Use the `exe-fixtures-generator` subagent** (factory/seed do testów).
4) Dokumentacja:
   - **Use the `exe-docs-writer` subagent** to uaktualnić `.doc/` (ADR/flow/zmiany).

Wynik fazy 2: działający kod, testy, uzupełniona dokumentacja.

---

## FAZA 3: Weryfikacja (dokładnie w tej kolejności)
1) **Use the `ver-lint-fixer` subagent**  
   - Uruchom `php-cs-fixer fix --config=.php-cs-fixer.php --dry-run --diff --using-cache=no` oraz pozostałe lintery; doprowadź do 0 błędów.
2) **Use the `ver-types-guardian` subagent**  
   - Kompilacja/typy/importy/interfejsy; 0 błędów kompilacji.
3) **Use the `ver-build-orchestrator` subagent**  
   - Kolejno: cache obrazów → indeks wyszukiwania → dokumentacja AI → build całego projektu.
4) **Use the `ver-test-runner` subagent**  
   - Uruchom pełny pakiet testów; każdy czerwony test = blokada do czasu naprawy.
5) **Use the `ver-vuln-scanner` subagent**  
   - Skan zależności; jeśli podatności krytyczne → zaproponuj aktualizacje.
6) **Use the `anl-performance-auditor` subagent** (jeśli applicable)
   - Verify no performance regressions introduced
   - Check database query efficiency
   - Validate caching strategies
   - Measure response times against baseline
7) **Use the `anl-security-auditor` subagent** (jeśli security-sensitive changes)
   - Scan for exposed credentials lub secrets
   - Verify SQL injection prevention
   - Check XSS protection measures  
   - Validate proper authorization checks
   - Ensure data encryption compliance

Krytyczne zasady: identyczne jak w poprzedniej wersji (0 błędów lint/kompilacji/testów, 0 podatności; nie commituj przy czerwonych testach).

---

## AUTO-FIX (inteligentny retry z type-aware logic)
Ustaw `ATTEMPT_COUNTER = 1`. Dla każdej próby z limits based on error type:
  * Linting: 1 próba (should be automatic)
  * Performance: 2 próby (complex analysis needed)  
  * Types: 3 próby (standard complexity)
  * Tests: 5 prób (may need multiple iterations)
  * Build: 2 próby (usually dependency issues)

- **Use the `fix-failure-diagnoser` subagent** to wskazać pierwszy blokujący błąd + zebrać minimalny repro/logi.
- **Use the `fix-root-cause-analyst` subagent** to dodać wpis do `{PATH_TO_REPLACE}/memory.md` wg `.claude/memory.md` z `Proposed Solution`.
- **Use the `fix-auto-fixer` subagent** to wdrożyć poprawkę i **ponownie** uruchomić właściwą część FAZY 3.
- Jeśli sukces: dopisz `Outcome: Successful` + performance impact analysis i przerwij pętlę.
- Jeśli porażka: dopisz `Outcome: Unsuccessful. Reason: ...`, `ATTEMPT_COUNTER++`. Po przekroczeniu type-specific limits – zakończ pracę, przygotuj raport końcowy (zawiera diagnozę prób + pytania o kontekst).

---

## FAZA 4: Finalizacja (tylko gdy FAZA 3 zakończona w 100%)
1) **Use the `fin-memory-scribe` subagent** to zaktualizować `{PATH_TO_REPLACE}/memory.md` (zgodnie z `.claude/memory.md`).
2) Oznacz w `{PATH_TO_REPLACE}/task.md` status „done”.
3) **Use the `fin-commit-bot` subagent** to utworzyć commit z poprawnym message.
4) **Use the `fin-diff-recorder` subagent** to wygenerować i zapisać diff:  
   `git diff $CURRENT_BRANCH..HEAD > {PATH_TO_REPLACE}/changes.diff`
5) **Use the `fin-merge-prepper` subagent** to przygotować PR (checklisty, recenzenci, załączniki).

---

# DETEKCJE I WARUNKI
- Zasoby:
  - Jeśli obecny link Figma → uruchom `anl-figma-spec` + `exe-component-stitcher`.
  - Jeśli tylko obrazy → `anl-asset-locator` + `exe-component-stitcher`.
  - Jeśli referencyjna strona → `anl-refsite-auditor`.

---

# OCZEKIWANE ARTEFAKTY
- 0 błędów kompilacji i lint, wszystkie testy zielone, brak podatności krytycznych.
- Zaktualizowane: `{PATH_TO_REPLACE}/task.md`, `{PATH_TO_REPLACE}/memory.md`.
- Plik `{PATH_TO_REPLACE}/changes.diff` i przygotowany PR.

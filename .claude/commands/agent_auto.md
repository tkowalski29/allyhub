# Command: AGENT_AUTO
# Description: Realizuje zadanie wg zdefiniowanego procesu. CC sam dobiera subagentów, ale musi przed wykonaniem przedstawić plan wyboru i uzasadnienie, zapisać je do artefaktów oraz respektować ograniczenia bezpieczeństwa.
# Arguments:
#   $TASK_ID (wymagane) – katalog .spec/$TASK_ID/ (task.md, memory.md)
#   --allow (opcjonalnie) – lista bloków dozwolonych do autoselekcji, np. anl,exe,ver,fix,fin (domyślnie wszystkie)
#   --deny (opcjonalnie) – lista nazw agentów lub bloków do zablokowania, np. exe-maker-sql,ver-build-orchestrator
#   --pin  (opcjonalnie) – lista agentów, których CC MA użyć jeśli to możliwe, np. exe-maker-php,ver-test-runner
# Output:
#   - Zrealizowane i zweryfikowane zadanie
#   - Plan doboru agentów i uzasadnienia w {PATH}/out_agent_plan.json
#   - Zaktualizowane {PATH}/task.md, {PATH}/memory.md, {PATH}/changes.diff (po sukcesie)

{PATH} = `.spec/$TASK_ID/`

# ZASADY AUTOSELEKCJI (obowiązkowe)
1) Utwórz {PATH}/out_agent_plan.json zawierający:
   - detected: { inputs: {figma:boolean, images:boolean, refsite:boolean}, is_epic:boolean }
   - chosen_agents: [ {phase, name, why, inputs_used} ... ]
   - constraints: { allow, deny, pin }
2) Dobór agentów wg prefixów (nasza lista):
   - anl-* do analizy, 
   - exe-* do implementacji, 
   - ver-* do weryfikacji, 
   - fix-* do auto-naprawy, 
   - fin-* do finalizacji.
3) Heurystyki wyboru (przykłady):
   - Zawsze uzywaj TDD `exe-tdd-driver` + `exe-test-writer`.
   - Jeśli jest link Figma → include `anl-figma-spec` (+ później `exe-component-stitcher`).
   - Jeśli są tylko obrazy → pomiń figmę, include `exe-component-stitcher`.
   - Jeśli jest strona referencyjna → include `anl-refsite-auditor`.
   - Jeśli to EPIC (task.md opisuje wielowątkowy zakres) → include `anl-epic-slicer` (pisze {PATH}/new_tasks_to_create.json z obiektami do utworzenia przez API) i zakończ po wygenerowaniu listy.
4) Bezpieczeństwo:
   - Stosuj least-privilege (nie podnoś narzędzi poza zakresem roli).
   - Szanuj --allow/--deny/--pin. Jeśli konflikt: priorytet `deny` > `pin` > `allow`.
5) Transparentność:
   - **PRZED wykonaniem** wypisz plan (chosen_agents) i krótkie „why” dla każdego wyboru w odpowiedzi oraz w {PATH}/out_agent_plan.json.
   - Każde faktyczne wywołanie subagenta loguj w {PATH}/memory.md (sekcja „Agent Call”).

# FAZA 1: Analiza i planowanie
1) Wczytaj {PATH}/task.md i (jeśli istnieje) {PATH}/memory.md.
2) Autodetekcja: wejścia (figma/images/refsite), czy to EPIC.
3) Stack to:
   - figma → **exe-component-stitcher**
   - angular → **exe-maker-angular**
4) Zasoby:
   - Autoselekcja `anl-asset-locator`; warunkowo `anl-figma-spec` i/lub `anl-refsite-auditor`.
5) Kryteria i architektura:
   - Autoselekcja `anl-acceptance-keeper` → AC + plan testów.
   - Autoselekcja `anl-solution-architect` → podejście KISS + biblioteki.
6) Performance i Security Assessment:
   - Jeśli changes dotyczą database/cache/API/queries → autoselekcja `anl-performance-auditor`
   - Always measure performance baseline for comparison
   - Auto-detect security-sensitive changes (auth, payment, user data) → autoselekcja `anl-security-auditor`

# FAZA 2: Wykonanie
1) TDD `exe-tdd-driver` + `exe-test-writer` + `exe-maker-<stack>`.
2) UI z aktywami? → `exe-component-stitcher`.
3) Integracja i dane → `exe-integration-writer` + `exe-fixtures-generator`.
4) Dokumentacja → `exe-docs-writer`.

# FAZA 3: Weryfikacja (ta kolejność)
1) `ver-lint-fixer` → 0 błędów lint (w tym `php-cs-fixer --dry-run`).
2) `ver-types-guardian` → 0 błędów kompilacji/typów.
3) `ver-build-orchestrator` → cache obrazów → indeks → dokumentacja AI → build.
4) `ver-test-runner` → wszystkie testy zielone.
5) `ver-vuln-scanner` → brak podatności krytycznych.
6) `anl-performance-auditor` (jeśli applicable) → no performance regressions.
7) `anl-security-auditor` (jeśli security-sensitive) → comprehensive security validation.

# AUTO-FIX (inteligentny retry z type-aware logic)
- Autoselekcja: `fix-failure-diagnoser` → `fix-root-cause-analyst` (dopisz wpis do {PATH}/memory.md wg `.claude/memory.md`) → `fix-auto-fixer` → **ponów właściwą FAZĘ**.
- Retry limits based on error type:
  * Linting: 1 próba (should be automatic)
  * Performance: 2 próby (complex analysis needed)  
  * Types: 3 próby (standard complexity)
  * Tests: 5 prób (may need multiple iterations)
  * Build: 2 próby (usually dependency issues)
- Po sukcesie: dopisz Outcome: Successful + performance impact analysis; po przekroczeniu limitów: przygotuj raport końcowy (diagnoza prób + pytania o kontekst).

# FAZA 4: Finalizacja
1) `fin-memory-scribe` → zaktualizuj {PATH}/memory.md.
2) Oznacz {PATH}/task.md jako „done”.
3) `fin-commit-bot` → commit (opisowy, zgodny ze standardem).
4) `fin-diff-recorder` → `git diff $CURRENT_BRANCH..HEAD > {PATH}/changes.diff`.
5) `fin-merge-prepper` → przygotuj PR (checklisty, recenzenci, załączniki).

# KRYTYCZNE ZASADY
- Nie ignoruj nieudanych testów; wszystkie komendy muszą zwracać exit code 0 przed przejściem dalej.
- Nie commituj przy czerwonych testach.
- Każda autodecyzja (dobór/zmiana agenta) musi być zapisana w {PATH}/out_agent_plan.json i {PATH}/memory.md.

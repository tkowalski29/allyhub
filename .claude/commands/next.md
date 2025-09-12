# Command: NEXT
# Description: Kompleksowa realizacja zadania z pełnym cyklem weryfikacji i samo-naprawą - od analizy przez implementację do testów
# Argument: $TASK_ID - Identyfikator zadania w katalogu .spec/, wewnątrz zadania znajduje sie plik task.md i memory.md
# Output: Zrealizowane i zweryfikowane zadanie z aktualizacją historii i gotowością do merge

{PATH_TO_REPLACE} - wskazuje na `.spec/$TASK_ID/`

**Faza 1: Analiza i planowanie**
1. Przeczytaj plik zadania: `.spec/$TASK_ID/task.md`.
2. Przeczytaj plik kontekstu i historii: `.spec/$TASK_ID/memory.md` (jezeli nie ma memory to oznacza ze odpalamy zadanie 1 raz).
3. Przeanalizuj `$OPERATION` w kontekście zawartości pliku, swojej wiedzy (`.doc/`) oraz najlepszych praktyk.
4. Stwórz plan działania krok po kroku. **Wyjaśnij co chcesz osiągnąć i dlaczego wybierasz konkretną metodę, architekturę lub bibliotekę.**
5. Gdy odnosze się do obrazek inny zasób który dostarczam znajduje się on zawsze w katalogu `.spec/$TASK_ID/`, odwołuję się po jego nazwie więc znajdź plik o którym wspominam.

---

**Faza 2: Wykonanie**
Na podstawie planu wykonaj `.spec/$TASK_ID/task.md`. Zawsze przestrzegaj zasady KISS.
1. Staraj się uzywać class tailwind zamiast pisać css ręcznie
2. Testy powinny być napisane do servisów które tworzysz lub funkcjonalności w nich które modyfikujesz
3. Tłumaczenia dodawaj do langów
4. Udokumentuj zmiany w kodzie i flow projektu w `.doc/`

---

**Faza 3: Weryfikacja**

Po ukończeniu pracy uruchom następującą sekwencję **w dokładnej kolejności**:

KROK 1: Jakość kodu i bezpieczeństwo typów
- napraw wszystkie błędy lint przed kontynuowaniem. Uruchamiaj ponownie aż do braku błędów.
- napraw wszystkie błędy kompilacji przed kontynuowaniem. Sprawdź typy, interfejsy, importy.

KROK 2: Walidacja budowy i infrastruktury
- zapewnia kompilację projektu: cache obrazów → indeks wyszukiwania → dokumentacja AI → budowa całego projektu, jeśli nie powiodło się: sprawdź logi budowy, napraw składnię/zależności, uruchom ponownie

KROK 3: Kompleksowe testowanie
- uruchamia wszystkich testów obejmujących (narzędzia, bezpieczeństwo, komponenty, hooki), jeśli jakikolwiek test nie powiedzie się: przeanalizuj nieudany test, napraw logikę kodu, uruchamiaj ponownie aż wszystkie będą zielone
- sprawdza podatności w zależnościach

KRYTYCZNE ZASADY:
- ❌ NIGDY nie ignoruj nieudanych testów - każdy błąd wskazuje na uszkodzoną funkcjonalność
- ✅ WSZYSTKIE polecenia muszą zwrócić kod wyjścia 0 (brak błędów) przed kontynuowaniem
- 🔧 Jeśli jakikolwiek krok się nie powiedzie: napraw główną przyczynę, następnie uruchom ponownie to konkretne polecenie
- ⚠️ Nie commituj kodu z nieudanymi testami

Oczekiwane wyniki:
- 0 błędów w kompilacji
- 0 błędów lint
- wszystkie testy jednostkowe przechodza pomyślnie
- budowa kończy się sukcesem
- 0 podatności bezpieczeństwa

---

**Faza 4: Finalizacja**

**JEŚLI WSZYSTKIE KROKI WERYFIKACJI PRZESZŁY POMYŚLNIE:**
1.  **Zaktualizuj plik `.spec/$TASK_ID/memory.md`, używając zasad i szablonów zdefiniowanych w `.claude/memory.md`.**
2.  Zaktualizuj plik `.spec/$TASK_ID/task.md`, oznaczając ukończone zadanie jako zakończone.
3.  Stwórz commit ze zmianami, generując zwięzłą ale opisową wiadomość zgodną ze standardami projektu.
4.  Wygeneruj diff i zapisz do pliku:
   ```bash
   git diff $CURRENT_BRANCH..HEAD > .spec/$TASK_ID/changes.diff
   ```
   - Zapisz różnice między gałęzią bazową a aktualną
   - Plik diff służy do dokumentacji wprowadzonych zmian

---
**W PRZECIWNYM RAZIE (JEŚLI JAKIKOLWIEK KROK WERYFIKACJI NIE POWIÓDŁ SIĘ):**

**Zainicjuj pętlę samo-naprawy (maksymalnie 3 próby).**
Ustaw licznik prób, `ATTEMPT_COUNTER = 1`.

**DLA KAŻDEJ PRÓBY (od 1 do 3):**

**Krok A: Diagnoza i log pamięci**
0.  Z każdą kolejną próbą myśl progresywnie głębiej o znalezieniu właściwego rozwiązania. Przy pierwszej próbie po prostu myśl; przy drugiej myśl intensywnie; a przy trzeciej myśl ultra intensywnie.
1.  Zidentyfikuj pierwszy napotkany błąd (błąd budowy, konkretny test który się nie powiódł, lub błąd lintera).
2.  **Stwórz nowy wpis w pliku `.spec/$TASK_ID/memory.md` dla próby samo-naprawy, używając struktury zdefiniowanej w `.claude/memory.md`.**

**Krok B: Implementacja poprawki**
1.  Zaimplementuj `Proposed Solution` opisane w `MEMORY`.

**Krok C: Ponowna weryfikacja i decyzja**
1.  Uruchom **pełną** sekwencję weryfikacji ponownie (Faza 3: Weryfikacja)
2.  **Jeśli ponowna weryfikacja przejdzie pomyślnie:**
    * Zaktualizuj wpis w `.spec/$TASK_ID/memory.md` dla tej próby dodając: `**Outcome:** Successful.`
    * **Przerwij pętlę samo-naprawy** i wróć do ścieżki sukcesu (górna sekcja "JEŚLI WSZYSTKIE KROKI WERYFIKACJI...").
3.  **Jeśli ponowna weryfikacja ponownie się nie powiedzie:**
    * Zaktualizuj wpis w `.spec/$TASK_ID/memory.md` dla tej próby dodając: `**Outcome:** Unsuccessful. Reason: [opisz co się nie powiodło - czy błąd jest taki sam czy pojawił się nowy].`
    * Zwiększ `ATTEMPT_COUNTER` o 1.
    * Przejdź do następnej iteracji pętli.

**JEŚLI PROBLEM UTRZYMUJE SIĘ PO 3 PRÓBACH:**

**Zatrzymaj pracę i zgłoś krytyczny błąd:**
1.  **Nie modyfikuj pliku `.spec/$TASK_ID/task.md`**. Plik `.spec/$TASK_ID/memory.md` już zawiera pełną historię prób.
2.  Przygotuj **szczegółowy raport końcowy** dla użytkownika, który zawiera:
    * Jasną wiadomość: "Praca została zatrzymana po 3 nieudanych próbach samo-naprawy."
    * Końcową analizę problemu, opartą na wiedzy zebranej ze wszystkich 3 prób.
    * Pełny log z pliku `.spec/$TASK_ID/memory.md` dotyczący tych 3 prób, aby użytkownik mógł zobaczyć twój proces myślowy.
    * **Bezpośrednią prośbę o pomoc**, zadając konkretne pytania, np.: "Nie jestem w stanie rozwiązać problemu X. Moje próby naprawy (opisane powyżej) doprowadziły do błędu Y. Czy masz jakiekolwiek sugestie dotyczące innego podejścia lub dodatkowego kontekstu, który mogę przegapić?".

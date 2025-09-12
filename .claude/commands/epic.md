# Command: EPIC
# Description: Generuje szczegółowy, wielofazowy plan realizacji dla epica, z naciskiem na TDD i mierzalne kryteria, dostosowany do wykonania przez AI
# Argument: $TASK_ID - Identyfikator zadania w katalogu .spec/, wewnątrz zadania znajduje sie plik out_epic.md
# Output: Nowy plik w formacie Markdown zapisany w ścieżce `.spec/$TASK_ID/out_epic.md`

### KROK 0: WERYFIKACJA WYMAGAŃ I ZAPIS PLANU

1.  Przeanalizuj poniższy opis zadania (epica) zawarty w `.spec/$TASK_ID/task.md`.
2.  **Jeśli uznasz, że opis jest niekompletny lub niejednoznaczny, wykonaj następujące kroki:**
    a.  Spróbuj znaleźć brakujący kontekst, odczytując pliki w katalogu `.doc/` w głównym katalogu projektu.
    b.  Jeśli po analizie plików nadal masz wątpliwości, **PRZERWIJ TWORZENIE PLANU**. Zamiast tego, zadaj użytkownikowi listę precyzyjnych, numerowanych pytań, które pomogą doprecyzować wymagania.
3.  **Pamiętaj: to jest projekt użytkownika, a nie modelu. Użytkownik podejmuje ostateczne decyzje. Twoją rolą jest zadawanie pytań w razie niepewności, a nie tworzenie założeń.**
4.  Jeśli wymagania są jasne, przejdź do generowania planu zgodnie z poniższą strukturą.
5.  **Gotowy plan zapisz jako nowy plik w lokalizacji `.spec/$TASK_ID/out_epic.md`.**

### STRUKTURA PLANU DO WYGENEROWANIA

⚠️ **ZAKAZ SZACOWANIA CZASU:** Nie określaj czasu potrzebnego na realizację zadań (dni, godziny, tygodnie). Zadania są wykonywane przez agenty AI, więc klasyczne szacowanie czasu jak dla ludzi jest bezcelowe.

---

# Plan Realizacji Epica: [Wstaw tu zwięzłą nazwę zadania z $TASK_DESCRIPTION]

## 1. Cele i Główne Założenia (Executive Summary)

Na podstawie `.spec/$TASK_ID/task.md`, zwięźle opisz:
- **Cel Biznesowy:** Co chcemy osiągnąć z perspektywy produktu/użytkownika?
- **Cel Techniczny:** Co musi zostać zaimplementowane, aby osiągnąć cel biznesowy?
- **Główne Założenia i Strategia:** Jaki jest ogólny plan i podejście?

### **Kryteria Ukończenia Sekcji:**
- `[ ]` Cel biznesowy i techniczny są jasno sformułowane i mierzalne.
- `[ ]` Wybrana strategia (np. migracja, greenfield) jest uzasadniona.
- `[ ]` Sekcja jest zrozumiała dla osób nietechnicznych (biznes, Product Owner).

## 2. Definicja Architektury i Zasad Pracy

Zaproponuj treść dokumentu, który będzie służył jako "źródło prawdy" dla tego zadania. Powinien on zawierać:
- **Architektura Rozwiązania:** Opis kluczowych komponentów i ich powiązań.
- **Stos Technologiczny:** Wymień wszystkie kluczowe technologie.
- **Struktura Projektu:** Zaproponuj strukturę katalogów i plików.
- **Konwencje i Standardy:** Określ zasady (nazewnictwo, git, commity, styl kodowania).

### **Kryteria Ukończenia Sekcji:**
- `[ ]` Zaproponowana architektura jest kompletna i gotowa do implementacji.
- `[ ]` Stos technologiczny jest zdefiniowany, włącznie z wersjami.
- `[ ]` Zasady pracy są jednoznaczne i nie pozostawiają miejsca na interpretację.

## 3. Analiza Ryzyk i Niejasności

Zidentyfikuj potencjalne problemy i pytania, które należy rozstrzygnąć **przed** rozpoczęciem prac.
- **Ryzyka Techniczne:**
- **Ryzyka Projektowe:**
- **Kluczowe Pytania do Biznesu/Product Ownera:**

### **Kryteria Ukończenia Sekcji:**
- `[ ]` Każde zidentyfikowane ryzyko ma przypisaną strategię mitygacji (uniknięcie, akceptacja, redukcja).
- `[ ]` Sformułowane pytania są konkretne i wymagają jednoznacznej odpowiedzi.
- `[ ]` Lista jest wyczerpująca i została skonsultowana z potencjalnymi interesariuszami.

## 4. Szczegółowy Plan Działania (Fazy i Zadania)

Podziel całe zadanie na logiczne, numerowane **fazy**. Każdą fazę rozbij na listę **konkretnych, technicznych zadań**.

**ZASADA NACZELNA: Wszystkie zadania implementacyjne (szczególnie w logice biznesowej) MUSZĄ być realizowane zgodnie z metodologią TDD (Test-Driven Development). Struktura zadań musi to odzwierciedlać.**

*Przykład struktury zadania w TDD:*

#### Zadanie: Implementacja funkcji `calculateDiscount(user, product)`
- `[ ]` **(RED)** Utwórz plik testu `calculateDiscount` i napisz pierwszy test sprawdzający zniżkę dla nowego użytkownika. Test powinien na razie nie przechodzić.
- `[ ]` Uruchom testy i **potwierdź**, że dokładnie ten jeden test faktycznie nie przechodzi z oczekiwanym błędem (np. `ReferenceError: calculateDiscount is not defined`).
- `[ ]` **(GREEN)** Zaimplementuj minimalną wersję funkcji `calculateDiscount` w pliku `calculateDiscount`, tak aby napisany test zaczął przechodzić.
- `[ ]` Uruchom testy i **potwierdź**, że wszystkie przechodzą.
- `[ ]` **(REFACTOR)** Dokonaj refaktoryzacji kodu funkcji (popraw czytelność, wydajność), a następnie **ponownie uruchom wszystkie testy i potwierdź, że wciąż przechodzą.**
- `[ ]` **(REPEAT)** Dodaj kolejny test dla innego przypadku (np. użytkownik premium) i powtórz cykl RED-GREEN-REFACTOR.

*(Stwórz właściwe fazy i zadania dla `.spec/$TASK_ID/task.md`, stosując powyższy wzorzec TDD dla zadań implementacyjnych)*

### **Kryteria Ukończenia Sekcji:**
- `[ ]` Wszystkie fazy są logicznie uporządkowane.
- `[ ]` Zadania są "atomowe" - małe i skupione na jednym, konkretnym celu.
- `[ ]` Zadania implementujące logikę są jawnie rozpisane w krokach TDD.
- `[ ]` Każde zadanie jest weryfikowalne (ma jasny cel do osiągnięcia).

## 5. Kryteria Akceptacji i Plan Testów

Zdefiniuj, jak zweryfikujemy, że zadanie zostało wykonane poprawnie.

### **Filozofia Testowania**
1.  **Testuj faktyczne implementacje, nie mocki:** Preferujemy testy integracyjne (np. testujące interakcję serwisu z prawdziwą, testową bazą danych), aby mieć pewność, że komponenty działają ze sobą. Mocki stosujemy oszczędnie, głównie do izolowania zewnętrznych systemów (np. API firm trzecich).
2.  **Dogłębne testowanie logiki, pragmatyczne testowanie UI:** Cała kluczowa logika biznesowa musi być w pełni pokryta testami jednostkowymi/integracyjnymi zgodnie z TDD. Interfejs użytkownika jest testowany głównie przez automatyczne testy E2E (np. Playwright, Cypress), które weryfikują kluczowe ścieżki użytkownika, a nie detale implementacyjne komponentów.

### **Plan Testów**
- **Testy Jednostkowe/Integracyjne (TDD):** Wymień kluczowe moduły/serwisy, które będą testowane w ten sposób (np. "Serwis do walidacji zamówień", "Logika kalkulacji ceny").
- **Testy E2E (End-to-End):** Wymień 3-5 kluczowych scenariuszy do zautomatyzowania (np. "Pełny proces od dodania produktu do koszyka po złożenie zamówienia").
- **Testy Manualne/Eksploracyjne:** Zdefiniuj obszary, które wymagają manualnej weryfikacji (np. "Sprawdzenie poprawności wizualnej na różnych urządzeniach").

### **Kryteria Ukończenia Sekcji:**
- `[ ]` Filozofia testowania jest jasno określona.
- `[ ]` Plan testów jest kompletny i rozróżnia typy testów.
- `[ ]` Zdefiniowano kluczowe scenariusze E2E, które stanowią "definition of done" dla całej funkcjonalności.

## 6. Proponowana Kolejność Realizacji (Roadmap)

Podsumuj zależności między fazami i zaproponuj logiczną kolejność ich wykonania. **NIE OKREŚLAJ czasu realizacji poszczególnych faz ani zadań.**

### **Kryteria Ukończenia Sekcji:**
- `[ ]` Kolejność jest logiczna i uwzględnia zależności techniczne (np. backend przed frontendem).
- `[ ]` Zidentyfikowano zadania, które mogą być realizowane równolegle.
- `[ ]` Roadmapa jest logicznie spójna i technicznie wykonalna.
- `[ ]` Brak jakichkolwiek szacowań czasowych (dni, godziny, tygodnie).

---

## ⚠️ WAŻNE: ZAPIS PLANU

**PAMIĘTAJ:** Zgodnie z punktem 5 z sekcji "KROK 0: WERYFIKACJA WYMAGAŃ I ZAPIS PLANU":

> **Gotowy plan zapisz jako nowy plik w lokalizacji `.spec/$TASK_ID/out_epic.md`.**

Po wygenerowaniu całego planu, **MUSISZ**:
1. Zapisać cały wygenerowany plan jako nowy plik Markdown
2. Nadać plikowi opisową nazwę odpowiadającą treści epica

# Command: BIZ_SPEC
# Description: BUSINESS SPECIFICATION: Przekształć opis biznesowy w precyzyjną specyfikację techniczną używając agentów biz-planner, biz-architect i biz-risk.
# Argument: $TASK_ID - Identyfikator zadania w katalogu .spec/, wewnątrz zadania znajduje się plik task.md z opisem biznesowym
# Output: Kompletna specyfikacja biznesowa z planem, architekturą i analizą ryzyk

{PATH_TO_REPLACE} - wskazuje na `.spec/$TASK_ID/`

---

## [1] BIZ-PLANNER: Analiza Wymagań Biznesowych

Użyj agenta `@biz-planner` do przeanalizowania wymagań biznesowych z `task.md` i wygenerowania strategicznego planu implementacji.

**Input:** Przeczytaj `{PATH_TO_REPLACE}/task.md` i przeanalizuj opis biznesowy, uwzględnij ściezki do plików i dokumentów.

**Output:** Wygeneruj `{PATH_TO_REPLACE}/out_business_plan.md` zawierający:
- Analizę wymagań biznesowych
- Dekompozycję funkcjonalności na moduły
- Priorytetyzację (MoSCoW)
- Plan implementacji w fazach (BEZ SZACUNKÓW CZASOWYCH)
- Kryteria sukcesu dla każdego modułu
- Analizę ryzyk biznesowych

**Format:** Użyj dokładnie formatu z `@biz-planner` agenta.

---

## [2] BIZ-ARCHITECT: Projektowanie Architektury

Użyj agenta `@biz-architect` do zaprojektowania architektury systemu na podstawie planu biznesowego.

**Input:** Przeczytaj wygenerowany `{PATH_TO_REPLACE}/out_business_plan.md` i przeanalizuj wymagania techniczne.

**Output:** Wygeneruj `{PATH_TO_REPLACE}/out_business_architecture.md` zawierający:
- Przegląd architektury wysokiego poziomu
- Specyfikację modułów z interfejsami
- Mapowanie przepływów danych
- Wymagania niefunkcjonalne (performance, security, scalability)
- Plan integracji z istniejącymi systemami
- Rekomendacje technologiczne

**Format:** Użyj dokładnie formatu z `@biz-architect` agenta.

---

## [3] BIZ-RISK: Analiza Ryzyk

Użyj agenta `@biz-risk` do przeprowadzenia szczegółowej analizy ryzyk związanych z implementacją.

**Input:** Przeczytaj `{PATH_TO_REPLACE}/out_business_plan.md` i `{PATH_TO_REPLACE}/out_business_architecture.md`.

**Output:** Wygeneruj `{PATH_TO_REPLACE}/out_risk_analysis.md` zawierający:
- Szczegółową analizę ryzyk biznesowych i technicznych
- Risk matrix z oceną prawdopodobieństwa i wpływu
- Strategie łagodzenia ryzyk
- Plan monitorowania i early warning system
- Plany contingency dla różnych scenariuszy
- Rekomendacje działań

**Format:** Użyj dokładnie formatu z `@biz-risk` agenta.

---

## [4] FINAL SPECIFICATION: Kompletna Specyfikacja

Na końcu wygeneruj kompletny dokument `{PATH_TO_REPLACE}/out_business_specification.md` zawierający podsumowanie wszystkich analiz:

```markdown
# Kompletna Specyfikacja Biznesowa - [TASK_NAME]

**Data:** [YYYY-MM-DD]
**Task ID:** {TASK_ID}
**Business Value:** [Wysoki/Średni/Niski]
**Complexity:** [Prosta/Średnia/Złożona]
**Risk Level:** [Niski/Średni/Wysoki]

## Podsumowanie Wykonawcze

### Cel Biznesowy
[Krótkie podsumowanie głównego celu biznesowego]

### Kluczowe Funkcjonalności
1. [Funkcjonalność 1] - [Priorytet]
2. [Funkcjonalność 2] - [Priorytet]
3. [Funkcjonalność 3] - [Priorytet]

### Architektura Wysokiego Poziomu
[Diagram lub opis architektury]

### Główne Ryzyka
1. [Ryzyko 1] - [Poziom] - [Status]
2. [Ryzyko 2] - [Poziom] - [Status]
3. [Ryzyko 3] - [Poziom] - [Status]

## Szczegółowe Specyfikacje

### 1. Plan Biznesowy
[Link do out_business_plan.md lub podsumowanie]

### 2. Architektura Systemu
[Link do out_business_architecture.md lub podsumowanie]

### 3. Analiza Ryzyk
[Link do out_risk_analysis.md lub podsumowanie]

## Rekomendacje Implementacyjne

### Priorytet 1 (Must Have)
- [ ] [Moduł 1] - [Odpowiedzialny]
- [ ] [Moduł 2] - [Odpowiedzialny]

### Priorytet 2 (Should Have)
- [ ] [Moduł 3] - [Odpowiedzialny]
- [ ] [Moduł 4] - [Odpowiedzialny]

### Priorytet 3 (Could Have)
- [ ] [Moduł 5] - [Odpowiedzialny]

## Kryteria Sukcesu

### Business Metrics
- [ ] [Metryka 1] - [Cel] - [Pomiar]
- [ ] [Metryka 2] - [Cel] - [Pomiar]

### Technical Metrics
- [ ] [Metryka 1] - [Cel] - [Pomiar]
- [ ] [Metryka 2] - [Cel] - [Pomiar]

## Następne Kroki

1. **Review & Approval:** [Kto] - [Kiedy]
2. **Technical Design:** [Kto] - [Kiedy]
3. **Implementation Start:** [Kto] - [Kiedy]
4. **Testing & Validation:** [Kto] - [Kiedy]
5. **Deployment:** [Kto] - [Kiedy]

## Załączniki

- `out_business_plan.md` - Szczegółowy plan biznesowy
- `out_business_architecture.md` - Specyfikacja architektury
- `out_risk_analysis.md` - Analiza ryzyk
- `task.md` - Oryginalny opis biznesowy
```

---

## [5] GENEROWANIE KOMPLEMENTARNYCH TASKÓW

Na podstawie analizy wygeneruj komplementarne taski implementacyjne. Każdy task powinien być w osobnym pliku z prefixem `{PATH_TO_REPLACE}/out_task_`.

### Zasady Generowania Tasków:

1. **Komplementarność:** Każdy task to kompletny, funkcjonalny feature - nie minimalny element
2. **Ograniczona Liczba:** Maksymalnie 1-3 taski na epik - każdy to znaczący, komplementarny feature
3. **Samowystarczalność:** Każdy task musi zawierać wszystkie informacje potrzebne do implementacji
4. **Niezależność:** Taski muszą być całkowicie niezależne - nie mogą powodować wyjątków ani błędów
5. **Brak Zależności:** Taski NIE MOGĄ mieć zależności od innych tasków - jeśli są zależne, muszą być połączone w jeden duży task oznaczony jako `{PATH_TO_REPLACE}/out_to_big_task_`
6. **Sprawdzanie Dependencies:** Taski mogą sprawdzać czy dane komponenty/pliki już istnieją
7. **Brak Szacunków Czasowych:** Nie ma mapowania czasów - procesy są automatyczne
8. **Priorytetyzacja:** Taski powinny być uporządkowane według priorytetów MoSCoW
9. **Wykrywanie Złożoności:** Jeśli funkcjonalności w tasku są zbyt rozbudowane logicznie, wygeneruj pliki `{PATH_TO_REPLACE}/out_to_big_task_` z propozycjami podziału

### Format Taska:

```markdown
# Task [NUMER]: [NAZWA TASKA]

**Priorytet:** [Must/Should/Could/Won't]
**Moduł:** [Nazwa modułu]
**Dependencies:** ZAWSZE "Brak" - taski muszą być w 100% niezależne

## Cel
[Szczegółowy opis co ma być zrobione]

## Wymagania
- [ ] [Wymaganie 1]
- [ ] [Wymaganie 2]
- [ ] [Wymaganie 3]

## Implementacja
### Krok 1: [Nazwa kroku]
[Szczegółowy opis implementacji]

### Krok 2: [Nazwa kroku]
[Szczegółowy opis implementacji]

## Sprawdzenie Dependencies

## Kryteria Sukcesu
- [ ] [Kryterium 1]
- [ ] [Kryterium 2]
- [ ] [Kryterium 3]

## Testy
- [ ] [Test 1]
- [ ] [Test 2]
- [ ] [Test 3]

## Uwagi
[Dodatkowe informacje, uwagi, ostrzeżenia]
```

### Wykrywanie Złożoności i Podział na Mniejsze Taski:

**Kryteria Złożoności (jeśli spełnione, wygeneruj `out_to_big_task_`):**

1. **Zbyt Małe Taski:** Task zawiera mniej niż 3-4 znaczące funkcjonalności biznesowe (taski mają być komplementarnymi featureami)
2. **Wielowarstwowość:** Task wymaga zmian w więcej niż 4 warstwach architektury (UI, Service, Data, API)
3. **Wielokomponentowość:** Task wymaga utworzenia więcej niż 8 nowych komponentów/klas
4. **Wieloetapowość:** Task ma więcej niż 12 kroków implementacji
5. **Wielozależności:** Task ma JAKIEKOLWIEK zależności od innych tasków (0 zależności wymagane)
6. **Wielotestowość:** Task wymaga więcej niż 15 różnych testów
7. **Zbyt Dużo Tasków:** Epik generuje więcej niż 3 taski (maksymalnie 1-3 taski na epik)

**Format Pliku `out_to_big_task_[NUMER].md`:**

```markdown
# Big Task Analysis: [NAZWA TASKA]

**Status:** Zbyt złożony - wymaga podziału na mniejsze taski
**Powód:** [Szczegółowe uzasadnienie dlaczego task jest zbyt rozbudowany]

## Analiza Złożoności

### Wykryte Problemy:
- [ ] **Wielofunkcyjność:** [Opis różnych funkcjonalności]
- [ ] **Wielowarstwowość:** [Opis warstw architektury]
- [ ] **Wielokomponentowość:** [Lista komponentów]
- [ ] **Wieloetapowość:** [Liczba kroków]
- [ ] **Wielozależności:** [Lista zależności]

## Proponowany Podział

### Task A: [Nazwa pierwszego mniejszego taska]
**Zakres:** [Opis funkcjonalności]
**Komponenty:** [Lista komponentów]
**Kroki:** [Liczba kroków implementacji]

### Task B: [Nazwa drugiego mniejszego taska]
**Zakres:** [Opis funkcjonalności]
**Komponenty:** [Lista komponentów]
**Kroki:** [Liczba kroków implementacji]

### Task C: [Nazwa trzeciego mniejszego taska]
**Zakres:** [Opis funkcjonalności]
**Komponenty:** [Lista komponentów]
**Kroki:** [Liczba kroków implementacji]

## Rekomendacje

1. **Podziel na mniejsze taski:** Każdy task powinien skupiać się na jednej funkcjonalności
2. **Ustal kolejność:** Taski powinny być uporządkowane według zależności
3. **Sprawdź niezależność:** Każdy task powinien być wykonalny niezależnie
4. **Ręczna decyzja:** Wymagana ręczna decyzja o podziale przed implementacją

## Następne Kroki

1. **Review:** Przejrzyj propozycję podziału
2. **Dostosuj:** Zmodyfikuj podział według potrzeb biznesowych
3. **Zatwierdź:** Zatwierdź finalny podział
4. **Wygeneruj:** Wygeneruj nowe taski na podstawie zatwierdzonego podziału
```

### Przykłady Komplementarnych Tasków:

**out_task_1.md** - Kompletny system autentykacji użytkowników (UI + Backend + API + Testy)
**out_task_2.md** - Pełny moduł zarządzania produktami (CRUD + UI + Walidacja + Integracje)
**out_task_3.md** - Kompletny system raportowania (Generowanie + Eksport + UI + API)

### Przykłady Zbyt Małych Tasków (NIE GENEROWAĆ):

~~**out_task_1.md** - Utworzenie podstawowej struktury modułu~~
~~**out_task_2.md** - Implementacja komponentów UI~~
~~**out_task_3.md** - Implementacja serwisów API~~
~~**out_task_4.md** - Konfiguracja routingu~~
~~**out_task_5.md** - Implementacja state management~~
~~**out_task_6.md** - Testy jednostkowe~~
~~**out_task_7.md** - Integracja z zewnętrznymi API~~
~~**out_task_8.md** - Optymalizacja wydajności~~

### Przykłady Plików `{PATH_TO_REPLACE}/out_to_big_task_`:

**out_to_big_task_1.md** - Analiza złożonego taska implementacji systemu płatności
**out_to_big_task_2.md** - Analiza złożonego taska implementacji panelu administracyjnego
**out_to_big_task_3.md** - Analiza złożonego taska implementacji systemu raportowania

---

## [6] WALIDACJA I WERYFIKACJA

Przed zakończeniem sprawdź czy:

1. **Completeness:** Wszystkie wymagania biznesowe zostały przeanalizowane
2. **Consistency:** Plan, architektura i analiza ryzyk są spójne
3. **Clarity:** Specyfikacje są jasne i precyzyjne
4. **Actionability:** Każdy moduł ma jasno określone kryteria sukcesu
5. **Traceability:** Można prześledzić od wymagań biznesowych do specyfikacji technicznej
6. **Task Independence:** Taski są samowystarczalne i mogą być wykonywane niezależnie
7. **No Time Estimates:** Brak szacunków czasowych w dokumentacji
8. **Complexity Analysis:** Złożone taski zostały zidentyfikowane i podzielone na mniejsze
9. **Big Task Files:** Pliki `out_to_big_task_` zostały wygenerowane dla złożonych funkcjonalności
10. **Error Prevention:** Taski nie powodują wyjątków ani błędów podczas wykonywania

**Jeśli coś wymaga poprawy, zaktualizuj odpowiednie dokumenty.**

---

## [7] FINAL OUTPUT

Na końcu wygeneruj podsumowanie wykonanych prac:

```markdown
# Business Specification Complete

✅ **Business Plan:** Wygenerowano strategiczny plan implementacji
✅ **Architecture Design:** Zaprojektowano architekturę modułową
✅ **Risk Analysis:** Przeprowadzono analizę ryzyk
✅ **Final Specification:** Utworzono kompletny dokument specyfikacji
✅ **Implementation Tasks:** Wygenerowano samowystarczalne taski

## Generated Files:
- `out_business_plan.md` - Plan biznesowy z priorytetami
- `out_business_architecture.md` - Architektura systemu
- `out_risk_analysis.md` - Analiza ryzyk
- `out_business_specification.md` - Kompletna specyfikacja
- `out_task_1.md` - Task implementacyjny 1
- `out_task_2.md` - Task implementacyjny 2
- `out_task_N.md` - Task implementacyjny N
- `out_to_big_task_1.md` - Analiza złożonego taska 1 (jeśli dotyczy)
- `out_to_big_task_2.md` - Analiza złożonego taska 2 (jeśli dotyczy)

## Ready for:
- Technical design review
- Implementation planning
- Resource allocation
- Automated task execution
- Manual review of complex tasks (out_to_big_task_ files)
- Decision making on task division
```

## WAŻNE UWAGI

1. **Brak Szacunków Czasowych:** Wszystkie procesy są automatyczne, więc nie ma potrzeby szacowania czasów
2. **Samowystarczalne Taski:** Każdy task zawiera wszystkie informacje potrzebne do implementacji
3. **Dependency Checking:** Taski mogą sprawdzać czy dane komponenty/pliki już istnieją
4. **Prefix out_:** Wszystkie generowane pliki mają prefix `out_`
5. **Niezależność:** Taski muszą być całkowicie niezależne - nie mogą powodować wyjątków ani błędów
6. **Dopuszczalne Duże Taski:** Duże taski są dopuszczalne, jeśli w pełni zaspokajają funkcjonalność
7. **Wykrywanie Złożoności:** Złożone taski są automatycznie identyfikowane i dzielone na mniejsze
8. **Pliki out_to_big_task_:** Generowane dla złożonych funkcjonalności wymagających ręcznej decyzji
9. **Ręczna Decyzja:** Wymagana ręczna decyzja o podziale złożonych tasków przed implementacją
10. **Error Prevention:** Wszystkie taski muszą być zaprojektowane tak, aby nie powodowały wyjątków

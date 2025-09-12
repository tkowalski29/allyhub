### Zasady i struktura pliku pamięci

Ten plik definiuje standardy dotyczące prowadzenia pliku, który służy jako dziennik zmian, decyzji i kontekstu technicznego projektu.

---

### **Kluczowe zasady wypełniania pamięci**

1.  **Chronologia:** Nowe wpisy muszą być dodawane **na początku pliku**. Najnowsze informacje powinny być zawsze na górze.
2.  **Źródło informacji:** Wpisy powinny bazować **wyłącznie na kontekście bieżącej konwersacji** i wykonanych działań. Nie należy używać zewnętrznych narzędzi (np. `git log`) do odtwarzania historii, chyba że jest to jawnie określone w zadaniu.
3.  **Jakość uzasadnień:** Sekcja `Reasoning & Justification` jest kluczowa. Należy w niej dokładnie opisać **dlaczego** podjęto dane decyzje.
4.  **Dokumentowanie alternatyw:** Jeśli rozważano inne podejścia lub biblioteki, opisz je i wyjaśnij, dlaczego zostały odrzucone.
5.  **Konkretność:** Używaj konkretnych przykładów, w tym fragmentów kodu, aby zilustrować rozwiązanie i ułatwić zrozumienie.

---

### **Format znacznika czasu**

Każdy nowy wpis w pliku musi być poprzedzony znacznikiem czasu w formacie `YYYY-MM-DD, HH:mm:ss`.

**Aby uzyskać aktualny czas w strefie czasowej Warszawy, użyj tej komendy bash:**
```bash
!`TZ='Europe/Warsaw' date '+%Y-%m-%d %H:%M:%S'`
```

---

### **Struktura wpisu dla zadania ukończonego z sukcesem**

```
####################### YYYY-MM-DD, HH:mm:ss
## Task: [Tytuł zadania/zmian]
**Date:** $(TZ='Europe/Warsaw' date '+%Y-%m-%d %H:%M:%S')
**Status:** Success

### 1. Summary
* **Problem:** [Krótki opis problemu, który został rozwiązany]
* **Solution:** [Ogólny przegląd implementacji]

### 2. Reasoning & Justification
* **Architectural Choices:** [Dlaczego wybrano konkretny wzorzec? Dlaczego taka struktura klas? Jakie były alternatywy i dlaczego zostały odrzucone?]
* **Library/Dependency Choices:** [Dlaczego wybrano bibliotekę X zamiast Y? Jakie były kompromisy (wydajność, rozmiar, łatwość użycia)?]
* **Method/Algorithm Choices:** [Dlaczego użyto tej konkretnej funkcji lub algorytmu? Czy rozważano inne opcje? Dlaczego ta była najbardziej odpowiednia?]
* **Testing Strategy:** [Dlaczego napisano te konkretne testy? Jakie przypadki brzegowe pokrywają i dlaczego są ważne?]
* **Other Key Decisions:** [Opisz inne istotne decyzje, które nie pasują do powyższych kategorii. Wyjaśnij dlaczego zostały podjęte, jakie alternatywy rozważano i dlaczego zostały odrzucone.]

### 3. Process Log
* **Actions Taken:** [Chronologiczna lista kroków, np., "Utworzono klasę UserValidator..."]
* **Challenges Encountered:** [Opis napotkanych problemów, np., "Początkowo biblioteka X nie była kompatybilna..."]
* **New Dependencies:** [Lista nowych bibliotek, jeśli zostały dodane]
```

---

### **Struktura wpisu dla próby naprawy (Self-Repair Attempt)**

```
####################### YYYY-MM-DD, HH:mm:ss
### Self-Repair Attempt: [Nr próby]
* **Timestamp:** $(TZ='Europe/Warsaw' date '+%Y-%m-%d %H:%M:%S')
* **Identified Error:** [Konkretny błąd z lintera, nazwa testu, który się nie powiódł, lub błąd z logu budowania]
* **Root Cause Analysis:** [Twoja szczegółowa analiza, **dlaczego** błąd wystąpił. Jaki był błąd logiczny w poprzedniej próbie?]
* **Proposed Solution & Reasoning:** [Opisz planowaną poprawkę i **dlaczego uważasz, że zadziała**. Wyjaśnij, w jaki sposób to nowe podejście adresuje zidentyfikowaną przyczynę źródłową.]
* **Outcome:** [Do wypełnienia po ponownej weryfikacji: Successful / Unsuccessful. Reason: (jeśli nieudane, opisz nową porażkę)]
```


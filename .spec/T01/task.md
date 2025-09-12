# Zadanie: macOS Floating HUD (menu bar app) z rozszerzaniem w dół i akcjami na hover

**STATUS: 90% COMPLETED** - All components implemented, 4 minor build issues to fix

## Cel

Stworzyć natywną aplikację macOS (Swift + SwiftUI + AppKit) działającą w **pasku menu**, która wyświetla **pływające okienko (HUD)**. Okienko:

1. jest przeciągalne po pulpicie,
2. **na hover** pokazuje przyciski: **Powiększ**, **Następny task**, **Stop**,
3. po kliknięciu **Powiększ** **rozszerza się w dół o 100 px** (animacja), ujawniając dodatkowy panel z informacjami,
4. drugi klik **Powiększ** przywraca rozmiar,
5. ma ikonę w pasku menu do szybkiego pokazywania/ukrywania HUD oraz Start/Stop.

## Zakres funkcjonalny (MVP)

* **Status bar item** (ikona „⏱”) z menu:

  * Show/Hide HUD
  * Start, Stop
  * Quit
* **HUD (NSPanel + SwiftUI)**:

  * Zaokrąglone rogi, półprzezroczyste tło, cień.
  * Zawsze na wierzchu (`.floating`), widoczne na wszystkich biurkach/Spaces, także przy full-screen.
  * **Przeciąganie po tle** (`isMovableByWindowBackground = true`).
  * **Hover reveal**: podstawowy pasek przycisków (Powiększ / Następny task / Stop) pojawia się dopiero, gdy kursor najedzie na HUD (z lekką animacją opacity).
  * **Expand/Collapse**: klik „Powiększ” zmienia wysokość okna **+100 px** (animacja). Zawartość rozszerzanej sekcji: placeholder z „Task details / Subtasks / ETA”.
  * Zapamiętywanie pozycji (autosave frame).
* **Timer / Task placeholder**:

  * Prosty 60-minutowy timer z formatem **HH\:MM\:SS** (monospace digits).
  * „Następny task” przełącza się po liście mock tasks (np. tablica w pamięci).
* **Tryb „agent”** (bez ikony w Docku): `LSUIElement = YES` w `Info.plist`.

## Technologie

* Xcode 15+
* Swift 5.9+
* SwiftUI + AppKit (NSStatusBar/NSStatusItem, NSPanel)
* Brak zewnętrznych zależności

## Struktura projektu

```
AllyHub/
 ├─ AllyHub.xcodeproj
 ├─ AllyHub/
 │   ├─ App/AllyHubApp.swift
 │   ├─ App/AppDelegate.swift
 │   ├─ StatusBar/StatusBarController.swift
 │   ├─ HUD/FloatingPanel.swift
 │   ├─ HUD/HUDView.swift                // widok kompaktowy + hover akcje
 │   ├─ HUD/HUDExpandedView.swift        // część ujawniana po powiększeniu
 │   ├─ Model/TimerModel.swift
 │   ├─ Model/TasksModel.swift
 │   └─ Resources/Info.plist
 └─ README.md
```

## Zachowanie UI (specyfikacja)

* **Domyślny rozmiar panelu**: \~420×96 px (kompakt).
* **Powiększony rozmiar**: 420×196 px (czyli +100 px w dół).
* **Animacja**: zmiana wysokości w **0.20–0.25 s** (NSAnimationContext lub z poziomu SwiftUI, ale realny resize okna NSPanel).
* **Hover**:

  * po wejściu kursora nad panel: w ciągu 150 ms pojawia się pasek akcji (opacity 0→1; przesunięcie 4–6 pt).
  * po wyjściu kursora: znika w 150 ms.
* **Przyciski na hover** (po prawej lub w górnym pasku HUD):

  * **Powiększ** (toggle; label zmienia się na „Zmniejsz” po ekspansji)
  * **Następny task**
  * **Stop** (pauzuje timer, label zmienia się na „Start” gdy zatrzymany)
* **Zawartość kompaktowa**:

  * Tekst w stylu „Try drag me around 🧡”
  * Aktualny **Task title** (z tasks modelu)
  * Wyróżniony licznik czasu **HH\:MM\:SS**
* **Zawartość rozszerzana** (+100 px):

  * Sekcja „More info”: placeholdery – np. 3 subtaski (checkboxy – tylko UI), przewidywane zakończenie (ETA = now + remaining), ewentualnie krótka notka.

## Implementacja – wskazówki dla agenta

* **Okno**: `NSPanel` borderless, `isOpaque=false`, `backgroundColor=.clear`, `hasShadow=true`, `level=.floating`, `collectionBehavior=[.canJoinAllSpaces, .fullScreenAuxiliary]`, `isMovableByWindowBackground=true`.
* **Hostowanie SwiftUI**: `NSHostingView(rootView: HUDView(...))` jako `contentView`.
* **Resize**: metoda `setFrame(_:display:animate:)` lub animacja w `NSAnimationContext.runAnimationGroup`.
* **Hover detection**:

  * W SwiftUI: `onHover { isHovering in ... }` → `withAnimation { showControls = isHovering }`.
* **Zapamiętywanie pozycji**: `setFrameAutosaveName("FloatingTimerFrame")`.
* **Status bar**: `NSStatusBar.system.statusItem(...)`, podpięte akcje: Show/Hide HUD, Start/Stop, Quit.
* **Info.plist**: `LSUIElement` = `YES`.
* **TasksModel**: prosta tablica `[Task(title: String)]`, indeks bieżącego; `nextTask()` zwiększa indeks modulo długość.
* **TimerModel**: 1-sekundowy `Timer` na RunLoop `.common`; `formatted` zwraca HH\:MM\:SS; `start/stop/reset`.

## Akceptacja (Definition of Done)

1. Aplikacja buduje się w Xcode bez błędów i uruchamia na macOS 13+.
2. Po starcie w pasku menu widoczna ikona „⏱”; z menu można:

   * pokazać/ukryć HUD,
   * wystartować/zatrzymać timer,
   * zakończyć aplikację.
3. HUD:

   * jest widoczny, przeciągalny, z półprzezroczystym tłem i cieniem,
   * **na hover** pokazuje przyciski (Powiększ / Następny task / Stop),
   * **Powiększ** zwiększa wysokość **dokładnie o 100 px** w dół (z animacją), i pokazuje dodatkową sekcję,
   * ponowne **Powiększ** (Zmniejsz) wraca do wymiaru kompaktowego,
   * **Następny task** zmienia nazwę zadania (placeholder z listy 3–5),
   * **Stop/Start** pauzuje/wznawia licznik; UI odzwierciedla stan,
   * po restarcie aplikacja pamięta pozycję HUD.
4. Brak ikony w Docku (agent app).

## Komendy/uruchomienie lokalne

* Otwórz projekt i uruchom:

  * `open AllyHub/AllyHub.xcodeproj` (lub `xed AllyHub`)
  * Run w Xcode (⌘R)
* Alternatywnie z CLI (opcjonalnie dodać prosty skrypt):

  ```bash
  xcodebuild -project AllyHub/AllyHub.xcodeproj \
             -scheme AllyHub \
             -configuration Release \
             -derivedDataPath build
  open build/Build/Products/Release/AllyHub.app
  ```

## Testy manualne (checklista)

* [ ] Ikona w pasku menu działa, menu rozwija się poprawnie.
* [ ] HUD pojawia się na środku ekranu przy pierwszym uruchomieniu.
* [ ] Przeciąganie HUD po desktopie działa płynnie.
* [ ] Na hover pokazują się przyciski i znikają po odsunięciu kursora.
* [ ] Klik **Powiększ**: +100 px, pokazuje dodatkową sekcję; ponowny klik – wraca.
* [ ] „Następny task” zmienia tytuł zadania (z listy).
* [ ] Start/Stop zatrzymuje/uruchamia licznik; format HH\:MM\:SS poprawny.
* [ ] Po zamknięciu i ponownym uruchomieniu pozycja HUD jest zapamiętana.
* [ ] Aplikacja nie ma ikony w Docku (LSUIElement=YES).

## Materiały do wypełnienia (placeholdery)

* `TasksModel.swift`: zainicjalizuj np.:

  ```swift
  let tasks = ["Email triage", "Spec doc review", "Prototype refactor", "Break"]
  ```
* `HUDExpandedView.swift`: pokaż 2–3 „Subtasks” (checkboxy tylko wizualne) i ETA wyliczone z `TimerModel.remaining`.

## Dalsze rozszerzenia (po MVP – nie robić teraz)

* Globalne skróty klawiszowe (start/stop, show/hide).
* Preferencje (domyślny czas, kolory, przezroczystość).
* Auto-snap HUD do krawędzi ekranu.
* Integracja z Reminders/Todoist/JIRA/… (źródło tasków).
* Ikona w pasku z live czasem (atrybut `statusItem.button?.attributedTitle`).

# Gradient Settings Documentation

## Overview
GradientSettings zarządza ustawieniami wyglądu aplikacji AllyHub, w tym:
- Wybór gradientu tła
- Przezroczystość w trybie rozszerzonym
- Tryb wyświetlania kompaktowego paska

## Typy gradientów

```swift
enum GradientType: String, CaseIterable, Identifiable {
    case blue = "blue"
    case red = "red" 
    case green = "green"
    case purple = "purple"
    case orange = "orange"
    case teal = "teal"
}
```

### Dostępne gradienty:
- **Blue**: Blue → Cyan (domyślny)
- **Red**: Red → Pink
- **Green**: Green → Mint
- **Purple**: Purple → Indigo
- **Orange**: Orange → Yellow
- **Teal**: Teal → Blue

## Tryby kompaktowego paska

```swift
enum CompactBarMode: String, CaseIterable, Identifiable {
    case tasks = "Tasks"
    case chat = "Chat Input"
}
```

### Dostępne tryby:
- **Tasks**: Wyświetla aktualne zadanie i timer
- **Chat Input**: Wyświetla pole do wprowadzania wiadomości czatu

## Właściwości

### Published Properties
- `selectedGradient: GradientType`: Aktualnie wybrany gradient (domyślnie: .blue)
- `expandedOpacity: Double`: Przezroczystość w trybie rozszerzonym (0.3-1.0, domyślnie: 0.7)
- `compactBarMode: CompactBarMode`: Tryb wyświetlania kompaktowego paska (domyślnie: .tasks)

## Funkcje publiczne

### Zarządzanie gradientem
```swift
func setGradient(_ gradient: GradientType)
```
Ustawia wybrany gradient i zapisuje ustawienia.

### Zarządzanie przezroczystością
```swift
func setExpandedOpacity(_ opacity: Double)
```
Ustawia przezroczystość dla trybu rozszerzonego (zakres: 0.3-1.0).

### Zarządzanie trybem kompaktowym
```swift
func setCompactBarMode(_ mode: CompactBarMode)
```
Ustawia tryb wyświetlania kompaktowego paska.

## Przechowywanie ustawień

Ustawienia są zapisywane w UserDefaults pod kluczami:
- `AllyHub.Gradient`: Wybrany typ gradientu
- `AllyHub.ExpandedOpacity`: Wartość przezroczystości
- `AllyHub.CompactBarMode`: Tryb kompaktowego paska

### Automatyczne ładowanie
Ustawienia są automatycznie ładowane przy inicjalizacji z UserDefaults.

### Automatyczne zapisywanie
Każda zmiana ustawień jest automatycznie zapisywana przez wywołanie `saveSettings()`.

## Integracja z UI

### Compact View
- Przezroczystość tła zmienia się w zależności od stanu hover:
  - Bez hover: 30% opacity
  - Z hover: 90% opacity
  
### Expanded View
- Używa `expandedOpacity` jako bazową przezroczystość
- Na hover: 100% opacity dla lepszej czytelności

### Settings Accordion
Zawiera sekcje:
1. **Gradient Theme**: Grid z dostępnymi gradientami
2. **Expanded View Transparency**: Slider do kontroli przezroczystości
3. **Compact Bar Display**: Radio buttons do wyboru trybu

## Przykład użycia

```swift
// W HUDView
.fill(
    gradientSettings.selectedGradient.gradient
        .opacity(backgroundOpacity)
)

// backgroundOpacity bazuje na:
private var backgroundOpacity: Double {
    if isExpanded {
        return isHovering ? 1.0 : gradientSettings.expandedOpacity
    } else {
        return isHovering ? 0.9 : 0.3
    }
}
```

## Zachowanie trybu kompaktowego

### Tasks Mode
Wyświetla:
- Tytuł aktualnego zadania
- Aktualny czas timera
- Przechodzi na hover controls przy najechaniu myszą

### Chat Mode  
Wyświetla:
- Pole tekstowe do wprowadzania wiadomości
- Przycisk wysyłania wiadomości
- Placeholder "Type message..."
- Auto-focus po przełączeniu trybu
# Tasks Model Documentation

## Overview
TasksModel zarządza zadaniami w aplikacji AllyHub, umożliwiając:
- Wyświetlanie aktualnego zadania
- Przełączanie między zadaniami
- Oznaczanie zadań jako ukończone/nieukończone
- Przechowywanie stanu zadań w UserDefaults

## Struktura Task

```swift
struct Task: Identifiable, Equatable, Codable {
    let id: UUID
    let title: String
    var isCompleted: Bool
    let createdAt: Date
}
```

### Właściwości:
- `id`: Unikalny identyfikator zadania
- `title`: Tytuł zadania
- `isCompleted`: Status ukończenia
- `createdAt`: Data utworzenia zadania

## Funkcjonalności

### Nawigacja po zadaniach
- `nextTask()`: Przechodzi do następnego zadania
- `previousTask()`: Przechodzi do poprzedniego zadania
- `goToTask(at index: Int)`: Przechodzi do zadania o podanym indeksie

### Zarządzanie statusem
- `markCurrentTaskCompleted()`: Oznacza aktualne zadanie jako ukończone i automatycznie przechodzi do następnego
- `markCurrentTaskIncomplete()`: Oznacza aktualne zadanie jako nieukończone
- `toggleCurrentTaskCompletion()`: Przełącza status aktualnego zadania

### Zarządzanie listą zadań
- `addTask(_ title: String)`: Dodaje nowe zadanie
- `removeTask(at index: Int)`: Usuwa zadanie o podanym indeksie
- `resetTasks()`: Resetuje zadania do domyślnych przykładów

## Computed Properties

- `currentTask`: Zwraca aktualne zadanie lub nil
- `currentTaskTitle`: Zwraca tytuł aktualnego zadania lub "No tasks available"
- `hasNextTask`: Sprawdza czy istnieje następne zadanie
- `hasPreviousTask`: Sprawdza czy istnieje poprzednie zadanie
- `completedTasksCount`: Liczba ukończonych zadań
- `progress`: Postęp jako wartość 0.0-1.0

## Integracja z API

### Pobieranie zadań z serwera
Aplikacja może wykorzystywać `tasksFetchURL` z CommunicationSettings do:
1. Pobrania zadań z zewnętrznego API podczas uruchamiania
2. Synchronizacji stanu zadań z serwerem
3. Aktualizacji listy zadań w czasie rzeczywistym

### Wysyłanie aktualizacji statusu
Gdy zadanie zostanie oznaczone jako ukończone, aplikacja wysyła POST do `taskUpdateURL`:

```swift
// Przykład integracji w markCurrentTaskCompleted()
func markCurrentTaskCompleted() {
    guard let currentTask = currentTask else { return }
    
    if let index = tasks.firstIndex(where: { $0.id == currentTask.id }) {
        tasks[index].isCompleted = true
        saveTasks()
        
        // Wyślij aktualizację do serwera
        sendTaskUpdateToServer(taskId: currentTask.id.uuidString, action: "completed")
        
        // Automatyczne przejście do następnego zadania
        if hasNextTask {
            nextTask()
        }
    }
}
```

## Przykłady domyślnych zadań
```swift
[
    Task(title: "Email triage"),
    Task(title: "Spec doc review"), 
    Task(title: "Prototype create"),
    Task(title: "Break")
]
```

## Przechowywanie danych
Zadania są przechowywane w UserDefaults pod kluczami:
- `AllyHub_Tasks`: Tablica zakodowanych zadań (JSON)
- `AllyHub_CurrentTaskIndex`: Indeks aktualnego zadania

## UI Integration
Model jest używany przez HUDView do:
- Wyświetlania aktualnego zadania w compact view
- Pokazywania szczegółów zadania w expanded view (zakładka Tasks)
- Obsługi przycisków "Mark Complete" i "Next Task"
- Aktualizacji UI w czasie rzeczywistym przez @Published properties
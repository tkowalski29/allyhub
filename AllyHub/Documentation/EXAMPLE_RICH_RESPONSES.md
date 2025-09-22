# Przykłady Odpowiedzi Rich Message

## Przykład 1: Tekst z akcjami

```json
{
  "type": "rich_message",
  "timestamp": "2024-01-01T12:00:00Z",
  "content": {
    "blocks": [
      {
        "type": "text",
        "content": "Czy chcesz aby zaprogramowałem nową funkcję?",
        "style": {
          "emphasis": "bold"
        }
      },
      {
        "type": "actions",
        "layout": "horizontal",
        "buttons": [
          {
            "id": "accept",
            "title": "Tak, zrób to",
            "style": "primary",
            "action": {
              "type": "callback",
              "payload": {"action": "start_programming", "confirmed": "true"}
            }
          },
          {
            "id": "decline",
            "title": "Nie teraz",
            "style": "secondary",
            "action": {
              "type": "callback",
              "payload": {"action": "cancel", "confirmed": "false"}
            }
          }
        ]
      }
    ]
  }
}
```

## Przykład 2: Alert z informacją

```json
{
  "type": "rich_message",
  "timestamp": "2024-01-01T12:00:00Z",
  "content": {
    "blocks": [
      {
        "type": "alert",
        "level": "warning",
        "title": "Uwaga!",
        "content": "Ta operacja może być niebezpieczna. Czy jesteś pewien?",
        "dismissible": false
      },
      {
        "type": "actions",
        "layout": "horizontal",
        "buttons": [
          {
            "id": "proceed",
            "title": "Kontynuuj",
            "style": "warning",
            "action": {
              "type": "callback",
              "payload": {"action": "proceed_dangerous"}
            }
          },
          {
            "id": "cancel",
            "title": "Anuluj",
            "style": "secondary",
            "action": {
              "type": "callback",
              "payload": {"action": "cancel_operation"}
            }
          }
        ]
      }
    ]
  }
}
```

## Przykład 3: Lista z postępem

```json
{
  "type": "rich_message",
  "timestamp": "2024-01-01T12:00:00Z",
  "content": {
    "blocks": [
      {
        "type": "text",
        "content": "Postęp implementacji:",
        "style": {"emphasis": "bold"}
      },
      {
        "type": "list",
        "style": "checklist",
        "items": [
          {"content": "Analiza wymagań", "checked": true},
          {"content": "Projektowanie API", "checked": true},
          {"content": "Implementacja backendu", "checked": false},
          {"content": "Testy jednostkowe", "checked": false}
        ]
      },
      {
        "type": "progress",
        "title": "Ukończenie",
        "value": 50,
        "max": 100,
        "label": "50% ukończone",
        "status": "in_progress"
      }
    ]
  }
}
```

## Przykład 4: Kod i linki

```json
{
  "type": "rich_message",
  "timestamp": "2024-01-01T12:00:00Z",
  "content": {
    "blocks": [
      {
        "type": "text",
        "content": "Oto przykład implementacji:"
      },
      {
        "type": "code",
        "content": "func calculateTotal(items: [Item]) -> Double {\n    return items.reduce(0) { $0 + $1.price }\n}",
        "language": "swift",
        "title": "Kalkulacja sumy"
      },
      {
        "type": "divider",
        "style": "line"
      },
      {
        "type": "link",
        "url": "https://developer.apple.com/documentation/swift",
        "title": "Swift Documentation",
        "description": "Oficjalna dokumentacja języka Swift"
      }
    ]
  }
}
```

## Przykład 5: Formularz

```json
{
  "type": "rich_message",
  "timestamp": "2024-01-01T12:00:00Z",
  "content": {
    "blocks": [
      {
        "type": "text",
        "content": "Podaj szczegóły nowej funkcji:"
      },
      {
        "type": "form",
        "title": "Nowa Funkcja",
        "fields": [
          {
            "id": "function_name",
            "type": "text",
            "label": "Nazwa funkcji",
            "placeholder": "np. calculateUserAge",
            "required": true
          },
          {
            "id": "description",
            "type": "textarea",
            "label": "Opis",
            "placeholder": "Co ma robić ta funkcja?"
          },
          {
            "id": "priority",
            "type": "number",
            "label": "Priorytet (1-10)",
            "required": true
          }
        ],
        "submit_button": {
          "id": "create_function",
          "title": "Utwórz funkcję",
          "style": "primary",
          "action": {
            "type": "callback",
            "payload": {"action": "create_function"}
          }
        }
      }
    ]
  }
}
```

## Implementacja w API

Twój backend powinien zwracać takie JSONy zamiast prostego tekstu w polu `answer`. AllyHub automatycznie wykryje czy odpowiedź jest rich message i wyrenderuje ją odpowiednio.

## Fallback

Jeśli JSON jest nieprawidłowy, AllyHub automatycznie wyświetli odpowiedź jako zwykły tekst.
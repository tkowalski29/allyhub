# Communication Settings API Documentation

## Overview
Dokument opisuje strukturę URL-i i API dla komunikacji aplikacji AllyHub z zewnętrznymi serwisami.

## URL Endpoints

### 1. Tasks Fetch URL
**Pole**: `tasksFetchURL`
**Opis**: URL do pobierania listy zadań

**Method**: GET
**Response Format**: JSON
```json
{
  "collection": [
    {
      "id": "string",
      "url": "string",
      "title": "string",
      "description": "string",
      "is_completed": boolean,
      "priority": "high|medium|low",
      "status": "todo|inprogress",
      "tags": []"string",
      "due_date": "ISO8601 timestamp",
      "created_at": "ISO8601 timestamp",
      "updated_at": "ISO8601 timestamp"
    }
  ],
  "count": number
}
```

**Przykład**: `https://api.example.com/tasks`

---

### 2. Task Update URL
**Pole**: `taskUpdateURL`
**Opis**: URL do wysyłania aktualizacji statusu zadania

**Method**: POST
**Request Format**: JSON
```json
{
  "id": "string",
  "action": "close | start | stop",
  "date": "ISO8601 timestamp",
  "timestamp": "ISO8601 timestamp"
}
```

**Response Format**: JSON
```json
{
  "success": boolean,
  "message": "string"
}
```

**Przykład**: `https://api.example.com/tasks/update`

---

### 3. Chat History URL
**Pole**: `chatHistoryURL`
**Opis**: URL do pobierania historii konwersacji

**Method**: GET
**Query Parameters**: 
- `limit` (optional): ilość wiadomości do pobrania (default: 50)
- `offset` (optional): offset dla paginacji (default: 0)
- `userId` (required): identyfikator użytkownika

**Response Format**: JSON
```json
{
  "messages": [
    {
      "id": "string",
      "content": "string",
      "senderId": "string",
      "senderName": "string",
      "timestamp": "ISO8601 timestamp",
      "type": "user|assistant|system"
    }
  ],
  "totalCount": number,
  "hasMore": boolean
}
```

**Przykład**: `https://api.example.com/chat/history?userId=user123&limit=50`

---

### 4. Chat Stream URL
**Pole**: `chatStreamURL`
**Opis**: URL dla streamowanej komunikacji z chatem (WebSocket lub Server-Sent Events)

**Protocol**: WebSocket lub HTTP POST
**Request Format** (POST): JSON
```json
{
  "message": "string",
  "userId": "string",
  "sessionId": "string",
  "timestamp": "ISO8601 timestamp"
}
```

**WebSocket Message Format**: JSON
```json
{
  "type": "message|typing|status",
  "content": "string",
  "senderId": "string",
  "timestamp": "ISO8601 timestamp"
}
```

**Przykład**: `wss://api.example.com/chat/stream` lub `https://api.example.com/chat/send`

---

### 5. Notifications Fetch URL
**Pole**: `notificationsFetchURL`
**Opis**: URL do pobierania powiadomień

**Method**: GET
**Query Parameters**:
- `userId` (required): identyfikator użytkownika
- `unreadOnly` (optional): czy pobierać tylko nieprzeczytane (default: false)
- `limit` (optional): ilość powiadomień (default: 20)

**Response Format**: JSON
```json
{
  "collection": [
    {
      "id": "string",
      "url": "string",
      "title": "string",
      "message": "string",
      "type": "info|warning|error|success",
      "is_read": boolean,
      "created_at": "ISO8601 timestamp"
    }
  ],
  "count_unread": number
}
```

**Przykład**: `https://api.example.com/notifications?userId=user123`

---

### 6. Notification Status URL
**Pole**: `notificationStatusURL`
**Opis**: URL do aktualizacji statusu powiadomienia (oznaczenie jako przeczytane/usunięte)

**Method**: POST/PATCH
**Request Format**: JSON
```json
{
  "id": "string",
  "action": "read | unread",
  "timestamp": "ISO8601 timestamp"
}
```

**Response Format**: JSON
```json
{
  "success": boolean,
  "message": "string"
}
```

**Przykład**: `https://api.example.com/notifications/status`

## Bezpieczeństwo

### Autoryzacja
Wszystkie zapytania powinny zawierać odpowiednie nagłówki autoryzacji:
- `Authorization: Bearer <token>`
- `X-API-Key: <api-key>`

### CORS
API powinno obsługiwać CORS dla domeny aplikacji AllyHub.

### Rate Limiting
Zaleca się implementację rate limitingu:
- Chat stream: 100 wiadomości/minutę
- Tasks API: 60 zapytań/minutę
- Notifications: 30 zapytań/minutę

## Obsługa błędów
Wszystkie endpointy powinny zwracać odpowiednie kody HTTP:
- 200: Sukces
- 400: Błędne dane wejściowe
- 401: Brak autoryzacji
- 403: Brak uprawnień
- 404: Zasób nie znaleziony
- 429: Za dużo zapytań
- 500: Błąd serwera

Format błędu:
```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": "string" // optional
  }
}
```
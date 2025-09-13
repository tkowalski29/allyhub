# Communication Settings API Documentation

## Overview
Dokument opisuje strukturę URL-i i API dla komunikacji aplikacji AllyHub z zewnętrznymi serwisami.

## URL Endpoints

### 1. Tasks Fetch URL
**Pole**: `tasksFetchURL`
**Opis**: URL do pobierania listy zadań
**Method**: POST
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
  "count": number,
  "priority_status": []"string"
}
```

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

---

### 3. Chat History URL
**Pole**: `chatHistoryURL`
**Opis**: URL do pobierania historii konwersacji
**Method**: POST

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

---

### 5. Notifications Fetch URL
**Pole**: `notificationsFetchURL`
**Opis**: URL do pobierania powiadomień
**Method**: POST
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

---

### 6. Notification Status URL
**Pole**: `notificationStatusURL`
**Opis**: URL do aktualizacji statusu powiadomienia (oznaczenie jako przeczytane/usunięte)
**Method**: POST
**Request Format**: JSON
```json
{
  "id": "string",
  "action": "read | unread | remove",
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

---

### 7. Actions Fetch URL
**Pole**: `actionsFetchURL`
**Opis**: URL do pobierania akcji do wykonania
**Method**: POST

**Response Format**: JSON
```json
{
  "collection": [
    {
      "id": "string",
      "url": "string",
      "method": "GET|POST",
      "title": "string",
      "message": "string",
      "parameters": {
        "name": {
          "type": "string",
          "placeholder": "string"
        },
        "file": {
          "type": "file",
          "placeholder": "string"
        },
        "class": {
          "type": "select",
          "placeholder": "string",
          "options": {
            "string": "string",
            "string": "string",
          }
        }
      }
    }
  ],
  "count": number
}
```

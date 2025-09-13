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

### 7. Task Create URL
**Pole**: `taskCreateURL`  
**Opis**: URL do tworzenia nowych zadań z różnymi metodami input (formularz, audio, screen recording)
**Method**: POST
**Content-Type**: `multipart/form-data` (dla zadań z plikami) lub `application/json` (dla zadań tekstowych)

**Request Format**: JSON/FormData
```json
{
  "title": "string",
  "description": "string", 
  "priority": "high|medium|low",
  "due_date": "ISO8601 timestamp", // opcjonalne
  "creation_type": "form|microphone|screen",
  "audio_url": "string", // opcjonalne - ścieżka do pliku audio
  "transcription": "string", // opcjonalne - transkrypcja audio/screen
  "tags": ["string"], // opcjonalne
  "user_id": "string" // opcjonalne
}
```

**Szczegóły dla różnych typów tworzenia:**

#### 7.1 Task Creation Type: "form"
- Standardowe tworzenie zadania przez formularz
- Wszystkie pola wprowadzone manualnie
- `audio_url` i `transcription` = null

#### 7.2 Task Creation Type: "microphone"  
- Zadanie utworzone przez nagranie audio
- `audio_url` zawiera ścieżkę do pliku nagrania (.m4a)
- `transcription` zawiera tekst z lokalnej transkrypcji WhisperKit
- `title` i `description` mogą być wypełnione przez użytkownika po nagraniu

#### 7.3 Task Creation Type: "screen"
- Zadanie utworzone przez nagranie ekranu
- `audio_url` zawiera ścieżkę do pliku screen recording (.mov)
- `transcription` zawiera informacje o nagranej aplikacji (np. "Screen recording: Google Chrome")
- `title` i `description` wypełniane przez użytkownika po nagraniu

**Response Format**: JSON
```json
{
  "success": boolean,
  "task_id": "string",
  "message": "string",
  "created_at": "ISO8601 timestamp"
}
```

**File Upload (dla audio/screen recordings):**
Pliki mogą być załączane jako `multipart/form-data`:
```
Content-Type: multipart/form-data

--boundary
Content-Disposition: form-data; name="task_data"
Content-Type: application/json

{JSON data jak wyżej}

--boundary  
Content-Disposition: form-data; name="recording_file"; filename="recording_123456.m4a"
Content-Type: audio/mp4

{binary audio/video data}

--boundary--
```

---

### 8. Actions Fetch URL
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

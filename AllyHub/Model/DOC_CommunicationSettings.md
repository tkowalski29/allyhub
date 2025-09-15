# Communication Settings API Documentation

## Overview
Dokument opisuje strukturę URL-i i API dla komunikacji aplikacji AllyHub z zewnętrznymi serwisami.

## URL Endpoints

### Task

#### 1. Tasks Fetch URL
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

#### 2. Task Update URL
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

### 3. Task Create URL
**Pole**: `taskCreateURL`  
**Opis**: URL do tworzenia nowych zadań z różnymi metodami input (formularz, audio, screen recording)
**Method**: POST
**Content-Type**: `multipart/form-data` (dla zadań z plikami) lub `application/json` (dla zadań tekstowych)
**Request Format**: JSON/FormData
```json
{
  "type": "form|microphone|screen",
  "title": "string",
  "description": "string", 
  "due_date": "ISO8601 timestamp",
  "transcription": {
    "content": "string",
    "duration": number
  }
}
```
**Response Format**: JSON
```json
{
  "success": boolean,
  "message": "string",
  "data": {
    "id": "string",
    "url": "string"
  }
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

### Chat

#### 1. Chat Collection URL
**Pole**: `chatHistoryURL`
**Opis**: URL do pobierania konwersacji
**Method**: POST
**Response Format**: JSON
```json
{
  "collection": [
    {
      "id": "string",
      "resume": "string"
    }
  ],
  "count": number
}
```

---

#### 2. Chat Message URL
**Pole**: `chatStreamURL`
**Opis**: URL dla komunikacji z chatem
**Method**: POST
**Response Format**: JSON
```json
{
    "conversationId": "string",
    "question": "string"
}
```
**Response Format**: JSON
```json
{
  "success": boolean,
  "message": "string",
  "data": {
    "conversationId": "string",
    "answer": "string"
  }
}
```

---

#### 3. Chat Get Conversation
**Pole**: `chatGetConversationURL`
**Opis**: URL dla historii danej konwersacji
**Method**: POST
**Response Format**: JSON
```json
{
    "conversationId": "string"
}
```
**Response Format**: JSON
```json
{
  "collection": [
    {
      "id": "string",
      "date": "string",
      "question": "string",
      "answer": "string"
    }
  ],
  "count": number
}
```

---

#### 4. Chat Create Conversation
**Pole**: `chatCreateConversationURL`
**Opis**: URL do zakladania nowej konwersacji
**Method**: POST
**Response Format**: JSON
```json
{
}
```
**Response Format**: JSON
```json
{
  "success": boolean,
  "message": "string",
  "data": {
    "conversationId": "string"
  }
}
```

---

### Notifications

#### 1. Notifications Fetch URL
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

#### 2. Notification Status URL
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

### Actions

### 1. Actions Fetch URL
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
          "order": 1,
          "type": "string",
          "placeholder": "string"
        },
        "file": {
          "order": 2,
          "type": "file",
          "placeholder": "string"
        },
        "class": {
          "order": 3,
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

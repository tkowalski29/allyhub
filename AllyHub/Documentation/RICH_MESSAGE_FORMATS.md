# AllyHub Rich Message Formats

## Overview

AllyHub supports rich message formatting through structured JSON responses. This allows the AI agent to provide interactive and visually rich content in both compact and expanded chat views.

## JSON Schema

### Base Message Structure

```json
{
  "type": "rich_message",
  "timestamp": "2024-01-01T12:00:00Z",
  "content": {
    "blocks": [
      // Array of content blocks
    ]
  }
}
```

## Content Block Types

### 1. Text Block
Simple text content with optional formatting.

```json
{
  "type": "text",
  "content": "This is a simple text message",
  "style": {
    "emphasis": "normal|bold|italic",
    "size": "small|normal|large",
    "color": "default|primary|success|warning|error"
  }
}
```

### 2. Quote Block
Highlighted quotation or important information.

```json
{
  "type": "quote",
  "content": "This is an important quote or highlighted information",
  "author": "Optional author name",
  "source": "Optional source"
}
```

### 3. Action Buttons
Interactive buttons for user actions.

```json
{
  "type": "actions",
  "layout": "horizontal|vertical",
  "buttons": [
    {
      "id": "action_yes",
      "title": "Yes",
      "style": "primary|secondary|success|warning|destructive",
      "action": {
        "type": "callback",
        "payload": {"action": "confirm", "value": true}
      }
    },
    {
      "id": "action_no",
      "title": "No",
      "style": "secondary",
      "action": {
        "type": "callback",
        "payload": {"action": "confirm", "value": false}
      }
    }
  ]
}
```

### 4. Link Block
Clickable links with preview information.

```json
{
  "type": "link",
  "url": "https://example.com",
  "title": "Example Website",
  "description": "Optional description of the link",
  "preview": {
    "image_url": "https://example.com/preview.jpg",
    "favicon_url": "https://example.com/favicon.ico"
  }
}
```

### 5. Image Block
Display images with optional captions.

```json
{
  "type": "image",
  "url": "https://example.com/image.jpg",
  "alt_text": "Alternative text description",
  "caption": "Optional image caption",
  "dimensions": {
    "width": 300,
    "height": 200
  },
  "thumbnail_url": "https://example.com/thumb.jpg"
}
```

### 6. File Block
File attachments with download capabilities.

```json
{
  "type": "file",
  "url": "https://example.com/document.pdf",
  "filename": "document.pdf",
  "size": 1024000,
  "mime_type": "application/pdf",
  "description": "Important document to review"
}
```

### 7. Video Block
Video content with playback controls.

```json
{
  "type": "video",
  "url": "https://example.com/video.mp4",
  "thumbnail_url": "https://example.com/thumb.jpg",
  "title": "Video Title",
  "duration": 120,
  "dimensions": {
    "width": 640,
    "height": 360
  }
}
```

### 8. Code Block
Syntax-highlighted code snippets.

```json
{
  "type": "code",
  "content": "console.log('Hello World');",
  "language": "javascript",
  "title": "Optional code title",
  "filename": "example.js"
}
```

### 9. List Block
Structured lists with various styles.

```json
{
  "type": "list",
  "style": "bullet|numbered|checklist",
  "items": [
    {
      "content": "First item",
      "checked": true
    },
    {
      "content": "Second item",
      "checked": false
    }
  ]
}
```

### 10. Data Table
Structured data in tabular format.

```json
{
  "type": "table",
  "headers": ["Name", "Value", "Status"],
  "rows": [
    ["Item 1", "100", "Active"],
    ["Item 2", "200", "Inactive"]
  ],
  "caption": "Optional table caption"
}
```

### 11. Progress Block
Progress indicators and status updates.

```json
{
  "type": "progress",
  "title": "Task Progress",
  "value": 75,
  "max": 100,
  "label": "75% Complete",
  "status": "in_progress|completed|error"
}
```

### 12. Alert Block
Important notifications and warnings.

```json
{
  "type": "alert",
  "level": "info|success|warning|error",
  "title": "Alert Title",
  "content": "Alert message content",
  "dismissible": true
}
```

### 13. Form Block
Interactive form elements.

```json
{
  "type": "form",
  "title": "Quick Form",
  "fields": [
    {
      "id": "input_name",
      "type": "text",
      "label": "Name",
      "placeholder": "Enter your name",
      "required": true
    },
    {
      "id": "input_email",
      "type": "email",
      "label": "Email",
      "placeholder": "Enter your email"
    }
  ],
  "submit_button": {
    "title": "Submit",
    "action": {
      "type": "callback",
      "payload": {"form_id": "quick_form"}
    }
  }
}
```

### 14. Card Block
Rich content cards with multiple elements.

```json
{
  "type": "card",
  "title": "Card Title",
  "subtitle": "Card Subtitle",
  "image_url": "https://example.com/image.jpg",
  "content": "Card description content",
  "actions": [
    {
      "title": "View Details",
      "action": {
        "type": "url",
        "url": "https://example.com/details"
      }
    }
  ]
}
```

### 15. Divider Block
Visual separation between content sections.

```json
{
  "type": "divider",
  "style": "line|space|decorative",
  "label": "Optional section label"
}
```

## Complete Example

```json
{
  "type": "rich_message",
  "timestamp": "2024-01-01T12:00:00Z",
  "content": {
    "blocks": [
      {
        "type": "text",
        "content": "Here's the information you requested:",
        "style": {"emphasis": "bold"}
      },
      {
        "type": "quote",
        "content": "Success is not final, failure is not fatal: it is the courage to continue that counts.",
        "author": "Winston Churchill"
      },
      {
        "type": "divider",
        "style": "line"
      },
      {
        "type": "actions",
        "layout": "horizontal",
        "buttons": [
          {
            "id": "accept",
            "title": "Accept",
            "style": "primary",
            "action": {
              "type": "callback",
              "payload": {"action": "accept"}
            }
          },
          {
            "id": "decline",
            "title": "Decline",
            "style": "secondary",
            "action": {
              "type": "callback",
              "payload": {"action": "decline"}
            }
          }
        ]
      }
    ]
  }
}
```

## Display Behavior

### Compact View
- Shows simplified version of blocks
- Text blocks: Truncated to 1-2 lines
- Images: Small thumbnails
- Buttons: Condensed to essential actions
- Cards: Title and subtitle only

### Expanded View
- Shows full rich content
- Images: Full size with captions
- All interactive elements enabled
- Complete form functionality
- Full table display

## Action Handling

### Callback Actions
When user interacts with buttons or forms, the client sends a callback to the chat API:

```json
{
  "type": "user_action",
  "action_id": "button_id",
  "payload": {
    "action": "confirm",
    "value": true
  }
}
```

### URL Actions
External links are opened in the default browser.

## Error Handling

If a block type is not recognized or malformed:
- Fall back to text display of the raw content
- Log warning for debugging
- Continue processing other blocks

## Implementation Notes

1. All URLs should be validated and sanitized
2. File downloads require user confirmation
3. Images should be cached for performance
4. Interactive elements need accessibility support
5. All content should be responsive to different window sizes
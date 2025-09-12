#!/bin/bash

# Notification webhook script for Claude Code
# This script receives notification data from Claude Code and sends it via webhook

set -e

# Configuration
WEBHOOK_URL="https://mws02-50168.wykr.es/webhook/f61301a3-2a5d-4a4f-ad73-411aadcc20c7"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Read JSON input from stdin
if [ -t 0 ]; then
    echo "Error: No input data provided via stdin" >&2
    exit 1
fi

# Read the JSON input
INPUT_DATA=$(cat)

# Create simple webhook payload with timestamp and original Claude Code data
PAYLOAD=$(cat <<EOF
{
  "timestamp": "${TIMESTAMP}",
  "claude_data": ${INPUT_DATA}
}
EOF
)

# Send the webhook
RESPONSE=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$WEBHOOK_URL" 2>/dev/null)

HTTP_CODE="${RESPONSE: -3}"
BODY="${RESPONSE%???}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "Notification sent successfully to n8n" >&2
else
    echo "Failed to send notification to n8n. HTTP Code: $HTTP_CODE" >&2
    echo "Response: $BODY" >&2
    exit 1
fi

exit 0 
# iPhone Shortcut Setup for Glucose Monitoring

## Overview
Configure your iPhone to automatically send glucose data to RedQueen when LibreView sends notifications.

## Method 1: iOS Shortcut Automation (Recommended)

### Step 1: Create the Shortcut
1. Open **Shortcuts** app on iPhone
2. Tap **+** to create new shortcut
3. Name it "Send Glucose to RedQueen"

### Step 2: Add Actions
1. **Get Clipboard** (if copying from notification)
2. **Get Contents of URL**:
   - URL: `http://YOUR_SERVER_IP:8080/glucose`
   - Method: POST
   - Request Body: JSON
   - JSON Content:
```json
{
  "value": 137,
  "trend": "Stable",
  "timestamp": "2026-03-14T19:30:00",
  "source": "libreview_notification"
}
```

### Step 3: Automation Trigger
1. Go to **Automation** tab in Shortcuts
2. Tap **+** → **Create Personal Automation**
3. Choose **Notification** trigger
4. Select **LibreView** app notifications
5. Add action: **Run Shortcut** → "Send Glucose to RedQueen"
6. Turn OFF "Ask Before Running"

## Method 2: Manual Share Sheet

1. When LibreView notification appears with glucose data
2. Long press notification → Share
3. Select "Send Glucose to RedQueen" shortcut

## Method 3: Background Automation (Advanced)

Use **Pushcut** or **Toolbox Pro** apps for more advanced automation:
- Parse notification content automatically
- Extract glucose value
- Send to webhook without manual action

## Server Endpoint

- **URL:** `http://95.111.227.193:8080/glucose`
- **Method:** POST
- **Content-Type:** application/json

## JSON Format

```json
{
  "value": 137,
  "trend": "Stable|Rising|Falling|DoubleUp|DoubleDown",
  "timestamp": "2026-03-14T19:30:00+02:00",
  "source": "libreview"
}
```

## Testing

Test the endpoint:
```bash
curl -X POST http://95.111.227.193:8080/glucose \
  -H "Content-Type: application/json" \
  -d '{"value": 137, "trend": "Stable"}'
```

## Security Note

The webhook runs on port 8080. Consider:
- Using HTTPS with reverse proxy
- Adding authentication token
- Restricting IP access

## Troubleshooting

1. **Connection refused**: Check firewall rules for port 8080
2. **Invalid JSON**: Ensure proper JSON formatting
3. **No alerts**: Check WhatsApp channel is configured

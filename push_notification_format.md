# Auto Check-in Push Notification Format

## 🚨 Push Notification Structure for Continuous Audio Alert

Send this **exact JSON structure** to trigger the continuous notification with music:

### **FCM Push Notification Payload:**

```json
{
  "to": "USER_FCM_TOKEN_HERE",
  "content_available": true,
  "priority": "high",
  "data": {
    "type": "auto_checkin_trigger",
    "task_id": "TASK_UUID_HERE",
    "task_name": "Clean Office Building A",
    "start_time": "14:30",
    "location": "123 Main St, Office Building A"
  },
  "android": {
    "priority": "high",
    "ttl": "3600s"
  },
  "apns": {
    "headers": {
      "apns-priority": "10",
      "apns-push-type": "background"
    },
    "payload": {
      "aps": {
        "content-available": 1,
        "sound": "",
        "badge": 1
      }
    }
  }
}
```

## 📋 **Required Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | String | ✅ | **Must be:** `"auto_checkin_trigger"` |
| `task_id` | String | ✅ | Unique task identifier (UUID) |
| `task_name` | String | ✅ | Human readable task name |
| `start_time` | String | ✅ | Task start time (HH:mm format) |
| `location` | String | ⚪ | Optional task location description |

## 🔊 **What Happens When Notification is Sent:**

1. **Background Handler Triggered** - App receives notification even when closed
2. **Continuous Music Starts** - Plays `assets/music/swiggy_new_order.mp3` in loop
3. **Vibration Pattern** - Repeating vibration every 3 seconds
4. **Persistent Notification** - Shows in notification tray with task details
5. **Music Continues** - Until user opens the app

## 🛑 **Stopping the Notification:**

- **Music stops automatically** when user opens the app
- **Notification dismisses** when app becomes active
- **Vibration stops** when music stops

## 📱 **Server Implementation Example (Node.js/Firebase Admin):**

```javascript
const admin = require('firebase-admin');

async function sendAutoCheckInTrigger(userToken, taskData) {
  const message = {
    token: userToken,
    data: {
      type: 'auto_checkin_trigger',
      task_id: taskData.id,
      task_name: taskData.name,
      start_time: taskData.startTime,
      location: taskData.location || ''
    },
    android: {
      priority: 'high',
      ttl: 3600000
    },
    apns: {
      headers: {
        'apns-priority': '10',
        'apns-push-type': 'background'
      },
      payload: {
        aps: {
          'content-available': 1,
          sound: '',
          badge: 1
        }
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Auto check-in trigger sent:', response);
    return response;
  } catch (error) {
    console.error('❌ Failed to send trigger:', error);
    throw error;
  }
}

// Usage:
await sendAutoCheckInTrigger('user_fcm_token', {
  id: 'task-uuid-123',
  name: 'Clean Office Building A',
  startTime: '14:30',
  location: '123 Main St, Office Building A'
});
```

## 🎵 **Audio File Requirements:**

- **File location:** `assets/music/swiggy_new_order.mp3`
- **Format:** MP3
- **Duration:** 3-5 seconds recommended for pleasant loop
- **Quality:** Medium quality sufficient (128kbps)
- **Volume:** App plays at 100% volume

## 📱 **Platform-Specific Notes:**

### **iOS:**
- Requires `content_available: 1` for background execution
- Limited background time (~30 seconds max)
- Music plays during background execution window

### **Android:**
- Works with device background restrictions
- Can play audio longer than iOS
- Respects Do Not Disturb settings

## 🧪 **Testing Instructions:**

1. **Deploy app** with audio file in `assets/music/swiggy_new_order.mp3`
2. **Get FCM token** from app logs when it starts
3. **Send test notification** using the JSON format above
4. **Verify behavior:**
   - Music starts immediately
   - Notification appears
   - Vibration pattern activates
   - Music stops when app opens

## ⚠️ **Important Notes:**

- **Background limitations apply** - iOS gives limited background time
- **Audio file required** - App will crash if `swiggy_new_order.mp3` missing
- **Permissions needed** - Notification and audio permissions required
- **Battery usage** - Continuous audio uses battery power
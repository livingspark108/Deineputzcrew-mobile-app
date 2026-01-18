{
    "message": {
      "token": "cDLV3r0OfEsWmC1EnZkHaH:APA91bGCUTn1u8KNUN_48j2DM5UKJ_YnIKVIlm8Co0AZvwOjGevf5RdVMDHQlI5joyUjkM98fq8HB5W8Y6CsZsFMcca8TtHNeUkitEL2TrAbByfdyTDVZNQ",
      "notification": {
        "title": "🔔 Auto Check-in Required",
        "body": "Time to check-in for ReinigungD at Cyber City"
        },
       "data": {
          "type": "auto_checkin_trigger",
            "task_id": "d9c98812-26a7-4250-9e7d-48c340a12cf5",
            "task_name": "ReinigungD",
            "start_time": "14:57:00",
            "location": "Cyber City"
        },
      "android": {
        "priority": "high",
        "notification": {
            "sound": "default",
            "channel_id": "auto_checkin_channel",
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "tag": "auto_checkin",
            "color": "#FF6B35"
        }
      },
      "apns": {
      "headers": {
        "apns-priority": "10",
        "apns-push-type": "alert"

      },
      "payload": {
        "aps": {
          "alert": {
            "title": "🔔 Auto Check-in Required", 
            "body": "Time to check-in for ReinigungD at Cyber City"
          },
          "sound": "swiggy_new_order.caf",
          "badge": 1
        }
      }
    }
    }
  }
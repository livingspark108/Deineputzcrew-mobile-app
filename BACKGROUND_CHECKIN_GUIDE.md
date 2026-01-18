# 📱 Automatic Background Check-in Guide

## 🚀 **New Feature: Auto Check-in**

Your app now supports automatic background check-in for tasks, even when the app is closed or in the background!

## 🎯 **How It Works**

### **When Tasks Load:**
1. **API fetches your tasks** for today
2. **Background monitoring starts** automatically
3. **Timer checks** every minute for task start times
4. **Auto check-in triggers** when task time arrives

### **Auto Check-in Conditions:**
- ✅ Task has `autoCheckin` enabled
- ✅ Current time matches task start time (within 5 minutes)
- ✅ User is in task location (if location-based)
- ✅ Task hasn't been manually checked in already

### **Background Processing:**
- **iOS**: Uses background app refresh and local notifications
- **Android**: Uses WorkManager for reliable background execution
- **Offline Support**: Stores check-ins locally and syncs when online

## 📋 **What Happens During Auto Check-in**

1. **Location Check**: Verifies you're within 100 meters of task location
2. **API Call**: Sends check-in request to server
3. **Local Storage**: Updates local database immediately
4. **Notification**: Shows success notification
5. **Offline Backup**: Stores check-in locally if API fails

## 🔔 **Notifications**

You'll receive notifications for:
- ✅ **Successful auto check-in**: "Auto Check-in Successful"
- 📱 **Offline auto check-in**: "Auto Check-in (Offline)"
- 🔄 **Background sync**: When offline check-ins are synced

## ⚙️ **Configuration**

### **Enable Auto Check-in**
Auto check-in is controlled by the task configuration in your admin panel. Tasks with `autoCheckin: true` will automatically check you in.

### **iOS Setup**
1. **Enable Background App Refresh** for Deineputzcrew app
2. **Allow Location Access** "Always" or "While Using App"
3. **Enable Notifications** for the app

### **Android Setup**
1. **Disable Battery Optimization** for Deineputzcrew app
2. **Allow Location Access** "Allow all the time"
3. **Enable Notifications** for the app

## 📍 **Location Requirements**

- **GPS must be enabled** on your device
- **App needs location permission** ("Always" for best results)
- **Check-in occurs** when you're within 100 meters of task location
- **Fallback available** if location services fail

## 🌐 **Offline Support**

- **Auto check-in works offline** - stores data locally
- **Automatic sync** when internet connection is restored
- **No data loss** - all check-ins are preserved
- **Status tracking** shows pending sync items

## 🔧 **Troubleshooting**

### **Auto Check-in Not Working?**

1. **Check Task Settings**:
   - Verify task has `autoCheckin: true`
   - Confirm start time is correct
   - Check if already manually checked in

2. **Check App Permissions**:
   - Location access set to "Always"
   - Notifications enabled
   - Background app refresh enabled

3. **Check Device Settings**:
   - Battery optimization disabled (Android)
   - App allowed to run in background
   - Do Not Disturb not blocking notifications

### **iOS Specific Issues**:
- **Low Power Mode** disables background processing
- **Force closing the app** may prevent background tasks
- **iOS 15+** requires explicit background app refresh

### **Android Specific Issues**:
- **Aggressive battery optimization** on some devices
- **Auto-start management** needs to be enabled
- **Background app limits** on some OEMs

## 📊 **Monitoring Status**

Use the **Background Tasks Widget** to monitor:
- ✅ Active monitoring status
- 📋 Number of tasks with auto check-in enabled
- ⏰ Upcoming tasks and their times
- 🔄 Refresh functionality

## 🔐 **Privacy & Security**

- **Location data** used only for check-in verification
- **All data encrypted** in transit
- **Local storage secured** with device security
- **No tracking** when not on duty

## 💡 **Best Practices**

1. **Keep app updated** for best reliability
2. **Ensure stable internet** for real-time sync
3. **Monitor notifications** for check-in confirmations
4. **Verify check-ins** in your task list
5. **Report issues** if auto check-in fails

## 🆘 **Support**

If auto check-in isn't working:
1. Check the troubleshooting steps above
2. Verify task settings with your administrator
3. Contact support with device/OS version info
4. Include any error notifications received

---

**Note**: Background functionality depends on device OS limitations and battery optimization settings. Results may vary based on device manufacturer and OS version.
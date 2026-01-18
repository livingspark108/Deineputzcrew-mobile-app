# Auto Check-in Test Guide

## Current Implementation Status ✅

### Background Task Manager
- **File:** `lib/background_task_manager.dart`
- **Features:**
  - ✅ Timer-based monitoring every minute
  - ✅ API integration with admin.deineputzcrew.de
  - ✅ Offline check-in storage
  - ✅ Location-based validation
  - ✅ Proper authentication with stored tokens

### Location Service  
- **File:** `lib/location_service.dart`
- **Features:**
  - ✅ Time-based auto check-in (when no GPS)
  - ✅ Location-based auto check-in (with GPS)
  - ✅ API integration matching main app
  - ✅ Offline fallback storage
  - ✅ Distance validation (within 300m)

### Main App Integration
- **File:** `lib/main.dart`
- ✅ BackgroundTaskManager initialization
- **File:** `lib/home.dart`  
- ✅ Background task sync integration

## Testing Steps

### 1. Check Background Service Status
- Open the app and verify in console logs:
- Look for: "🔄 BackgroundTaskManager initialized"
- Look for: "📋 Loaded X tasks from database"

### 2. Time-based Auto Check-in Test
- Create a task for current time (within next 5 minutes)
- Enable auto check-in for the task
- Keep app in background
- Should trigger auto check-in at task start time

### 3. Location-based Auto Check-in Test
- Create a task for current time and location
- Enable auto check-in
- Be within 300m of task location
- Should trigger both time and location validation

### 4. Console Log Monitoring
Key logs to watch for:

#### Background Task Manager:
```
🔍 Checking X tasks for auto check-in eligibility
🎯 Found eligible task: [TaskName]
🚀 Performing auto check-in for task: [TaskName]
✅ Auto check-in successful for task: [TaskName]
```

#### Location Service:
```
🌍 Starting location monitoring service
📍 Using location: [lat], [lng]
🎯 Time-based auto check-in triggered for: [TaskName]
✅ API check-in successful
```

## Debugging Issues

### "No valid tasks for auto check-in"
- Check task date matches today (yyyy-MM-dd format)
- Verify auto check-in is enabled on task
- Ensure task status is not "completed"
- Check task time window (start time has passed, end time not reached)

### "User denied permissions"
- Grant location permissions to app
- Enable "Always" location access for background operation
- Check iOS Settings > Privacy & Security > Location Services

### API Connection Issues
- Verify network connectivity
- Check authentication token is valid
- Confirm admin.deineputzcrew.de API is accessible

## Expected Behavior

1. **App Launch:** Background task manager starts monitoring
2. **Task Time Arrives:** Auto check-in triggered automatically  
3. **Online Mode:** Direct API call to server
4. **Offline Mode:** Stored locally, synced when online
5. **Location Validation:** Confirms user is within 300m of task location
6. **Notification:** User notified of successful auto check-in

## Recent Fixes Applied
- ✅ Fixed API endpoint mismatch (admin.deineputzcrew.de)
- ✅ Corrected authentication token format
- ✅ Fixed task loading from main app database
- ✅ Enhanced debugging output
- ✅ Improved offline storage handling
- ✅ Fixed compilation errors in parameter passing
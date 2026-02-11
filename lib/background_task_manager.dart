import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import 'app_metadata.dart';
import 'task_model.dart';
import 'db_helper.dart';
import 'location_service.dart';

class BackgroundTaskManager {
  static const String _taskChannelId = 'task_background_channel';
  static const String _autoCheckinTask = 'auto_checkin_task';
  static const String _taskMonitoringTask = 'task_monitoring';
  
  static FlutterLocalNotificationsPlugin? _notifications;
  static Timer? _taskTimer;
  static List<Task> _activeTasks = [];

  /// Initialize background task system
  static Future<void> initialize() async {
    try {
      print('🔄 Initializing BackgroundTaskManager...');
      
      // Initialize local notifications
      await _initializeNotifications();
      
      // Initialize WorkManager for background processing
      await _initializeWorkManager();
      
      // Start monitoring tasks
      await startTaskMonitoring();
      
      print('✅ BackgroundTaskManager initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize BackgroundTaskManager: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeNotifications() async {
    _notifications = FlutterLocalNotificationsPlugin();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications!.initialize(initSettings);

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _notifications!
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _taskChannelId,
              'Task Notifications',
              description: 'Automatic task check-in notifications',
              importance: Importance.high,
              enableVibration: true,
            ),
          );
    }
  }

  /// Initialize WorkManager for background processing
  static Future<void> _initializeWorkManager() async {
    if (!kDebugMode) {
      // Only in release mode - WorkManager has limitations in debug
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
    }
  }

  /// Start monitoring tasks and set up timers
  static Future<void> startTaskMonitoring() async {
    print('📡 Starting task monitoring...');
    
    // Load current tasks
    await _loadTasks();
    
    // Set up periodic check (every minute)
    _taskTimer?.cancel();
    _taskTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTaskTimes();
    });
    
    // Schedule background work
    if (!kDebugMode) {
      await Workmanager().registerPeriodicTask(
        'task_monitor',
        _taskMonitoringTask,
        frequency: const Duration(minutes: 15), // Minimum allowed
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
        ),
      );
    }
    
    print('✅ Task monitoring started');
  }

  /// Load tasks from database/API
  static Future<void> _loadTasks() async {
    try {
      // Load from local database first
      try {
        _activeTasks = await DatabaseHelper().getAllTasks();
        print('📋 Loaded ${_activeTasks.length} tasks from local DB');
      } catch (e) {
        print('⚠️ Failed to load from local DB: $e');
        _activeTasks = [];
      }
      
      // If no tasks in database, try to get them from the main app's cache
      if (_activeTasks.isEmpty) {
        await _loadTasksFromMainApp();
      }
      
      // Try to refresh from API (non-critical)
      try {
        await _refreshTasksFromAPI();
      } catch (e) {
        print('⚠️ Failed to refresh from API (non-critical): $e');
      }
      
      // Debug: Print task details
      if (_activeTasks.isNotEmpty) {
        print('📊 Task details:');
        for (final task in _activeTasks) {
          print('   - ${task.taskName}: startTime=${task.startTime}, autoCheckin=${task.autoCheckin}, punchIn=${task.punchIn}');
        }
        
        // Check which tasks are eligible for auto check-in
        final eligibleTasks = _activeTasks.where((task) => 
          !task.punchIn && task.autoCheckin).toList();
        print('🎯 ${eligibleTasks.length} tasks eligible for auto check-in');
      } else {
        print('ℹ️ No valid tasks for auto check-in');
      }
    } catch (e, stackTrace) {
      print('⚠️ Error loading tasks: $e');
      print('🐞 Stack trace: $stackTrace');
    }
  }
  
  /// Load tasks from main app's shared preferences or database
  static Future<void> _loadTasksFromMainApp() async {
    try {
      // Try to get tasks from the old database helper
      final oldDbHelper = DBHelper();
      final taskMaps = await oldDbHelper.getTasks();
      
      print('📋 Found ${taskMaps.length} tasks from main app database');
      
      for (final taskMap in taskMaps) {
        try {
          // ✅ Add validation before converting
          if (taskMap['id'] == null) {
            print('⚠️ Skipping task with null id');
            continue;
          }
          final task = Task.fromMap(taskMap);
          final dbHelper = DatabaseHelper();
          await dbHelper.insertTask(task);
          _activeTasks.add(task);
        } catch (e) {
          print('⚠️ Error converting task: $e');
          print('   Task data: $taskMap');
        }
      }
    } catch (e) {
      print('⚠️ Error loading tasks from main app: $e');
    }
  }

  /// Refresh tasks from API
  static Future<void> _refreshTasksFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId'); // Main app uses 'userId'
      final token = prefs.getString('token'); // Main app uses 'token'
      
      if (userId == null || token == null) {
        print('⚠️ No user credentials found for API refresh');
        return;
      }

      print('🔄 Refreshing tasks from API for user: $userId');
      
      // Use the same API endpoint as main app
      const url = 'https://admin.deineputzcrew.de/api/get_user_detail/';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'token $token',
        },
          body: json.encode({
            "id": userId,
            "app_version": AppMetadata.appVersion,
            "mobile_type": AppMetadata.mobileType,
          }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> taskByDate = data['task_by_date'] ?? [];
          
          // Flatten all tasks (same logic as main app)
          final List<Task> tasks = taskByDate.expand((dayData) {
            final String day = dayData['day'] ?? "";
            final String date = dayData['date'] ?? "";
            final List<dynamic> jsonTasks = dayData['tasks'] ?? [];

            return jsonTasks
                .where((t) => (t['status'] ?? '').toLowerCase() != 'completed')
                .map((t) => Task.fromJson(t, day: day, date: date));
          }).toList();
          
          _activeTasks = tasks;
          
          // Save to local database
          final dbHelper = DatabaseHelper();
          await dbHelper.clearAllTasks(); // Clear old tasks
          for (final task in _activeTasks) {
            await dbHelper.insertTask(task);
          }
          
          print('🔄 Refreshed ${_activeTasks.length} tasks from API');
        } else {
          print('⚠️ API returned success=false: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        print('⚠️ API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error refreshing tasks from API: $e');
    }
  }

  /// Check if any tasks need automatic check-in
  static Future<void> _checkTaskTimes() async {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    print('⏰ Checking task times at $currentTime');
    print('📋 Total active tasks: ${_activeTasks.length}');

    if (_activeTasks.isEmpty) {
      print('ℹ️ No active tasks to check');
      return;
    }

    for (final task in _activeTasks) {
      print('🔍 Evaluating task: ${task.taskName}');
      print('   - Start time: ${task.startTime}');
      print('   - Auto checkin: ${task.autoCheckin}');
      print('   - Already punched in: ${task.punchIn}');
      
      if (await _shouldAutoCheckIn(task, now)) {
        print('🎯 Auto check-in triggered for: ${task.taskName}');
        await _performAutoCheckIn(task);
      } else {
        print('⏭️ Skipping task: ${task.taskName} (not eligible)');
      }
    }
  }

  /// Check if task should auto check-in
  static Future<bool> _shouldAutoCheckIn(Task task, DateTime now) async {
    try {
      print('🔍 Checking auto check-in eligibility for: ${task.taskName}');
      
      // Check SharedPreferences for actual punch status
      final prefs = await SharedPreferences.getInstance();
      final punchedInTaskId = prefs.getString('punchedInTaskId');
      
      if (punchedInTaskId != null && punchedInTaskId.isNotEmpty) {
        print('❌ User already punched in to task: $punchedInTaskId');
        return false;
      }
      
      // Skip if already checked in
      if (task.punchIn) {
        print('❌ Already punched in');
        return false;
      }
      
      // Check if auto check-in is enabled for this task
      if (!task.autoCheckin) {
        print('❌ Auto checkin not enabled');
        return false;
      }

      // Parse task start time
      final taskStartTime = _parseTimeString(task.startTime);
      if (taskStartTime == null) {
        print('❌ Could not parse start time: ${task.startTime}');
        return false;
      }

      // Check if current time matches or is past start time
      final currentMinutes = now.hour * 60 + now.minute;
      final taskMinutes = taskStartTime.hour * 60 + taskStartTime.minute;
      
      print('⏰ Current time: ${now.hour}:${now.minute} ($currentMinutes minutes)');
      print('⏰ Task time: ${taskStartTime.hour}:${taskStartTime.minute} ($taskMinutes minutes)');
      
      // Auto check-in if current time is within 5 minutes of start time
      final timeDifference = currentMinutes - taskMinutes;
      print('⏱️ Time difference: $timeDifference minutes');
      
      if (timeDifference >= 0 && timeDifference <= 5) {
        print('✅ Time window valid for auto check-in');
        
        // Check if we're in the right location (if location-based)
        if (task.lat.isNotEmpty && task.longg.isNotEmpty) {
          print('📍 Checking location requirement...');
          final inLocation = await _isInTaskLocation(task);
          print('📍 In task location: $inLocation');
          return inLocation;
        }
        print('✅ No location requirement - proceeding with auto check-in');
        return true;
      } else {
        print('❌ Outside time window (need 0-5 minute difference)');
      }
      
      return false;
    } catch (e) {
      print('⚠️ Error checking if should auto check-in: $e');
      return false;
    }
  }

  /// Parse time string to DateTime
  static DateTime? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (e) {
      print('⚠️ Error parsing time string $timeStr: $e');
    }
    return null;
  }

  /// Check if user is in task location
  static Future<bool> _isInTaskLocation(Task task) async {
    try {
      print('📍 Checking location for task: ${task.taskName}');
      print('📍 Task location: ${task.lat}, ${task.longg}');
      
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Location permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Location permission denied');
          // Allow check-in anyway if permission is denied
          return true;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('⚠️ Location permission permanently denied');
        // Allow check-in anyway if permission is permanently denied
        return true;
      }
      
      // Try to get current position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        print('📍 Current position: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('⚠️ Could not get current position: $e');
        
        // Try to get last known position
        try {
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            print('📍 Using last known position: ${position.latitude}, ${position.longitude}');
          }
        } catch (e2) {
          print('⚠️ Could not get last known position: $e2');
        }
      }
      
      if (position == null) {
        print('⚠️ No position available - allowing check-in anyway');
        return true;
      }
      
      final taskLat = double.parse(task.lat);
      final taskLng = double.parse(task.longg);
      
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        taskLat,
        taskLng,
      );
      
      print('📏 Distance to task location: ${distance.toStringAsFixed(1)}m');
      
      // Within 100 meters
      final isInRange = distance <= 100;
      print('📍 In range: $isInRange');
      return isInRange;
    } catch (e) {
      print('⚠️ Error checking location: $e');
      // If location check fails, allow check-in anyway
      return true;
    }
  }

  /// Perform automatic check-in
  static Future<void> _performAutoCheckIn(Task task) async {
    try {
      print('🚀 Performing auto check-in for task: ${task.taskName}');
      
      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        print('📍 Current position: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('⚠️ Could not get location for auto check-in: $e');
        try {
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            print('📍 Using last known position: ${position.latitude}, ${position.longitude}');
          }
        } catch (e2) {
          print('⚠️ Could not get last known position: $e2');
        }
      }
      
      // Use task location if no current position and format to 4 decimals
      String lat;
      String lng;
      
      if (position != null) {
        lat = position.latitude.toStringAsFixed(4);
        lng = position.longitude.toStringAsFixed(4);
      } else {
        // Parse and format stored coordinates
        final taskLat = double.tryParse(task.lat) ?? 0.0;
        final taskLng = double.tryParse(task.longg) ?? 0.0;
        lat = taskLat.toStringAsFixed(4);
        lng = taskLng.toStringAsFixed(4);
      }
      
      print('📍 Using coordinates: $lat, $lng');
      
      // Try to send to API
      final success = await _sendCheckInToAPI(task.id, lat, lng);
      
      if (success) {
        // Update local database
        await _updateTaskCheckInStatus(task.id);
        
        // Show notification
        await _showAutoCheckInNotification(task);
        
        print('✅ Auto check-in successful for task: ${task.taskName}');
      } else {
        // Store for later sync
        await _storeOfflineCheckIn(task.id, lat, lng);
        await _showAutoCheckInNotification(task, offline: true);
        
        print('📱 Auto check-in stored offline for task: ${task.taskName}');
      }
      
    } catch (e) {
      print('❌ Error performing auto check-in: $e');
    }
  }

  /// Send check-in data to API
  static Future<Map<String, dynamic>> _sendCheckInToAPIWithStatus(String taskId, String lat, String lng) async {
    try {
      print('🚀 Sending auto check-in to API for task: $taskId');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('⚠️ No auth token found');
        return {'success': false, 'shouldRetry': true, 'message': 'No auth token'};
      }

      // Use the same API endpoint as main app
      const url = 'https://admin.deineputzcrew.de/api/punch-in/';
      
      // Load default auto check-in image from assets
      print('📸 Creating auto check-in image...');
      final ByteData imageData = await rootBundle.load('assets/images/auto_check_in.jpeg');
      final Directory tempDir = await getTemporaryDirectory();
      final String imagePath = '${tempDir.path}/auto_check_in_${DateTime.now().millisecondsSinceEpoch}.jpeg';
      final File imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageData.buffer.asUint8List());
      
      // Verify the image file was created successfully
      if (!await imageFile.exists()) {
        print('❌ Failed to create auto_check_in.jpeg at ${imagePath}');
        return {'success': false, 'shouldRetry': true, 'message': 'Failed to create image file'};
      } else {
        print('✅ Created auto_check_in.jpeg at ${imagePath}');
      }
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'token $token';
      
      // Add form fields
      request.fields['task_id'] = taskId;
      request.fields['lat'] = lat;
      request.fields['long'] = lng;
      request.fields['auto_checkin'] = 'true';
      request.fields['timestamp'] = DateTime.now().toIso8601String();
      
      // Attach image file
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        imagePath,
        filename: 'auto_check_in.jpeg',
      ));
      
      print('📦 Request fields: ${request.fields}');
      print('📦 Request files: ${request.files.length} (${imagePath})');
      
      final response = await request.send();
      
      // Clean up the temporary image file
      try {
        await imageFile.delete();
        print('🗑️ Cleaned up temporary image file');
      } catch (e) {
        print('⚠️ Failed to delete temporary image: $e');
      }
      final responseBody = await response.stream.bytesToString();
      
      print('📱 API Response: ${response.statusCode}');
      print('📱 Response body: $responseBody');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ API check-in successful');
        
        // Update SharedPreferences to mark user as punched in
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('punchedInTaskId', taskId);
        await prefs.setString('punchInTime', DateTime.now().toIso8601String());
        
        return {'success': true, 'shouldRetry': false, 'message': 'Success'};
      } else if (response.statusCode == 400) {
        // Check if already punched in
        try {
          final responseData = json.decode(responseBody);
          final errorMessage = responseData['error']?.toString() ?? '';
          
          if (errorMessage.contains('Already punched in today')) {
            print('✅ Already punched in - removing from sync queue');
            return {'success': false, 'shouldRetry': false, 'message': 'Already punched in today'};
          }
        } catch (e) {
          // If we can't parse the response, treat as retriable error
        }
        
        print('❌ API request failed with status: ${response.statusCode}');
        return {'success': false, 'shouldRetry': true, 'message': responseBody};
      } else {
        print('❌ API request failed with status: ${response.statusCode}');
        return {'success': false, 'shouldRetry': true, 'message': responseBody};
      }
    } catch (e) {
      print('⚠️ Error sending check-in to API: $e');
      return {'success': false, 'shouldRetry': true, 'message': e.toString()};
    }
  }

  /// Send check-in data to API (backwards compatibility)
  static Future<bool> _sendCheckInToAPI(String taskId, String lat, String lng) async {
    final result = await _sendCheckInToAPIWithStatus(taskId, lat, lng);
    return result['success'] == true;
  }

  /// Update task check-in status in local database
  static Future<void> _updateTaskCheckInStatus(String taskId) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.updateTaskPunchIn(taskId, true);
      
      // Update in memory
      final taskIndex = _activeTasks.indexWhere((t) => t.id == taskId);
      if (taskIndex != -1) {
        _activeTasks[taskIndex] = Task(
          id: _activeTasks[taskIndex].id,
          taskName: _activeTasks[taskIndex].taskName,
          startTime: _activeTasks[taskIndex].startTime,
          endTime: _activeTasks[taskIndex].endTime,
          locationName: _activeTasks[taskIndex].locationName,
          priority: _activeTasks[taskIndex].priority,
          status: _activeTasks[taskIndex].status,
          lat: _activeTasks[taskIndex].lat,
          longg: _activeTasks[taskIndex].longg,
          punchIn: true, // Updated
          punchOut: _activeTasks[taskIndex].punchOut,
          breakIn: _activeTasks[taskIndex].breakIn,
          breakOut: _activeTasks[taskIndex].breakOut,
          day: _activeTasks[taskIndex].day,
          date: _activeTasks[taskIndex].date,
          autoCheckin: _activeTasks[taskIndex].autoCheckin,
          autoCheckout: _activeTasks[taskIndex].autoCheckout,
          totalWorkTime: _activeTasks[taskIndex].totalWorkTime,
          radius: _activeTasks[taskIndex].radius, // Preserve existing radius
        );
      }
    } catch (e) {
      print('⚠️ Error updating task check-in status: $e');
    }
  }

  /// Store offline check-in for later sync
  static Future<void> _storeOfflineCheckIn(String taskId, String lat, String lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineCheckins = prefs.getStringList('offline_checkins') ?? [];
      
      final checkInData = {
        'task_id': taskId,
        'lat': lat,
        'long': lng,
        'auto_checkin': 'true',
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'punch-in',
      };
      
      offlineCheckins.add(json.encode(checkInData));
      await prefs.setStringList('offline_checkins', offlineCheckins);
      
      // Update SharedPreferences to mark user as punched in
      await prefs.setString('punchedInTaskId', taskId);
      await prefs.setString('punchInTime', DateTime.now().toIso8601String());
      
      print('📦 Stored offline check-in for task: $taskId');
    } catch (e) {
      print('⚠️ Error storing offline check-in: $e');
    }
  }

  /// Show auto check-in notification
  static Future<void> _showAutoCheckInNotification(Task task, {bool offline = false}) async {
    try {
      await _notifications?.show(
        task.id.hashCode,
        '✅ Auto Check-in ${offline ? '(Offline)' : 'Successful'}',
        'Task: ${task.taskName}\nTime: ${DateTime.now().toString().substring(11, 16)}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _taskChannelId,
            'Task Notifications',
            channelDescription: 'Automatic task check-in notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      print('⚠️ Error showing notification: $e');
    }
  }

  /// Sync offline check-ins when connection is restored
  static Future<void> syncOfflineCheckIns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineCheckins = prefs.getStringList('offline_checkins') ?? [];
      
      if (offlineCheckins.isEmpty) return;
      
      print('🔄 Syncing ${offlineCheckins.length} offline check-ins...');
      
      final List<String> remainingCheckIns = [];
      
      for (final checkInStr in offlineCheckins) {
        final checkInData = json.decode(checkInStr) as Map<String, dynamic>;
        
        // Format coordinates to 4 decimals before sending
        final lat = double.tryParse(checkInData['lat'] ?? '0.0')?.toStringAsFixed(4) ?? '0.0';
        final lng = double.tryParse(checkInData['long'] ?? '0.0')?.toStringAsFixed(4) ?? '0.0';
        
        final result = await _sendCheckInToAPIWithStatus(
          checkInData['task_id'] ?? '',
          lat,
          lng,
        );
        
        // If success OR already punched in, remove from queue
        // If shouldRetry is false (like "already punched in"), don't keep in queue
        if (result['success'] == true || result['shouldRetry'] == false) {
          // Successfully synced or no need to retry - don't add to remaining
          print('✅ Check-in processed: ${result['message']}');
        } else {
          // Failed and should retry - keep in queue
          remainingCheckIns.add(checkInStr);
          print('⚠️ Check-in failed, will retry: ${result['message']}');
        }
      }
      
      // Update the list with remaining check-ins
      await prefs.setStringList('offline_checkins', remainingCheckIns);
      
      final synced = offlineCheckins.length - remainingCheckIns.length;
      print('✅ Synced $synced offline check-ins, ${remainingCheckIns.length} remaining');
      
    } catch (e) {
      print('⚠️ Error syncing offline check-ins: $e');
    }
  }

  /// Clean up old pending tasks (1+ days old)
  static Future<void> cleanupOldTasks() async {
    try {
      print('🧹 Checking for old pending tasks to cleanup...');
      
      final dbHelper = DBHelper();
      final oldTasks = await dbHelper.getOldPendingTasks();
      
      if (oldTasks.isEmpty) {
        print('ℹ️ No old pending tasks found');
        return;
      }
      
      print('🗑️ Found ${oldTasks.length} old pending tasks to cleanup');
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        print('⚠️ No auth token for cleanup - skipping');
        return;
      }
      
      for (final taskData in oldTasks) {
        final taskId = taskData['id'] ?? '';
        final taskName = taskData['task_name'] ?? 'Unknown';
        final taskDate = taskData['date'] ?? '';
        
        print('🗑️ Cleaning up old task: $taskName (Date: $taskDate)');
        
        // Call API to mark task as expired/completed
        final success = await _callTaskCleanupAPI(taskId, token);
        
        if (success) {
          // Remove from local database
          await dbHelper.deleteOldTask(taskId);
          print('✅ Cleaned up task: $taskName');
        } else {
          print('⚠️ Failed to cleanup task: $taskName - keeping in DB');
        }
      }
      
      print('✅ Old task cleanup completed');
      
    } catch (e) {
      print('⚠️ Error during old task cleanup: $e');
    }
  }

  /// Call API to mark old task as expired/completed
  static Future<bool> _callTaskCleanupAPI(String taskId, String token) async {
    try {
      // You can customize this API endpoint and payload as needed
      const url = 'https://admin.deineputzcrew.de/api/task-cleanup/';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'task_id': taskId,
          'reason': 'Auto cleanup - task expired (1+ days old)',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      print('📱 Cleanup API Response: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('📱 Cleanup API Body: ${response.body}');
      }
      
      return response.statusCode == 200 || response.statusCode == 201;
      
    } catch (e) {
      print('⚠️ Error calling cleanup API for task $taskId: $e');
      return false;
    }
  }

  /// Stop task monitoring
  static Future<void> stopTaskMonitoring() async {
    _taskTimer?.cancel();
    if (!kDebugMode) {
      await Workmanager().cancelByUniqueName('task_monitor');
    }
    print('🛑 Task monitoring stopped');
  }

  /// Get active tasks
  static List<Task> getActiveTasks() => _activeTasks;

  /// Manually refresh tasks
  static Future<void> refreshTasks() async {
    await _loadTasks();
  }
}

/// Background callback dispatcher for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('🔄 Background task executed: $task');
      
      switch (task) {
        case 'task_monitoring':
          // Load tasks and check times in background
          await BackgroundTaskManager._loadTasks();
          await BackgroundTaskManager._checkTaskTimes();
          break;
      }
      
      return Future.value(true);
    } catch (e) {
      print('❌ Background task error: $e');
      return Future.value(false);
    }
  });
}
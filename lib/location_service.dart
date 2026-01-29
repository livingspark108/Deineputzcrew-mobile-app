import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'db_helper.dart';
import 'task_model.dart';

/// Background Location Service for Auto Check-in/Check-out
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Timer? _locationCheckTimer;
  StreamSubscription<Position>? _positionStream;
  bool _isMonitoring = false;
  
  // Task data for offline checks
  List<Task> _cachedTasks = [];
  
  // Callback for timer updates
  Function(String taskId, DateTime punchInTime)? _onAutoCheckInCallback;

  /// Start monitoring location for auto check-in/checkout
  Future<void> startMonitoring({
    List<Task>? tasks,
    Function(String taskId, DateTime punchInTime)? onAutoCheckIn,
  }) async {
    if (_isMonitoring) {
      debugPrint("⚠️ Location monitoring already active");
      return;
    }

    // Cache tasks for offline usage
    if (tasks != null) {
      _cachedTasks = tasks;
      debugPrint("📋 Cached ${tasks.length} tasks for offline monitoring");
    }

    // Set callback
    _onAutoCheckInCallback = onAutoCheckIn;

    _isMonitoring = true;
    debugPrint("🌍 Starting location monitoring service");

    // Check location every 15 seconds for more responsive offline mode
    _locationCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkLocationForAutoActions(),
    );

    // Also listen to continuous position updates (if permission allows)
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always) {
        const locationSettings = LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 50, // Update every 50 meters
        );
        
        _positionStream = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          (Position position) {
            debugPrint("📍 Position update: ${position.latitude}, ${position.longitude}");
            _checkLocationForAutoActions();
          },
          onError: (error) {
            debugPrint("❌ Position stream error: $error");
          },
        );
      }
    } catch (e) {
      debugPrint("⚠️ Could not start position stream: $e");
    }
  }

  /// Stop monitoring location
  void stopMonitoring() {
    debugPrint("🛑 Stopping location monitoring service");
    _locationCheckTimer?.cancel();
    _locationCheckTimer = null;
    _positionStream?.cancel();
    _positionStream = null;
    _isMonitoring = false;
  }

  /// Check location and trigger auto check-in/checkout if needed
  Future<void> _checkLocationForAutoActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final punchedInTaskId = prefs.getString('punchedInTaskId');
      
      // Get current position with fallback to last known location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5), // Reduced timeout for offline mode
          desiredAccuracy: LocationAccuracy.medium,
        );
      } catch (e) {
        debugPrint("⚠️ Could not get current position: $e");
        
        // Try to get last known position or use cached location
        try {
          position = await Geolocator.getLastKnownPosition();
          if (position != null) {
            debugPrint("📍 Using last known position: ${position.latitude}, ${position.longitude}");
          }
        } catch (e2) {
          debugPrint("⚠️ Could not get last known position: $e2");
          
          // Use cached location from preferences if available
          final lastLat = prefs.getDouble('last_lat');
          final lastLng = prefs.getDouble('last_lng');
          final lastLocationTime = prefs.getString('last_location_time');
          
          if (lastLat != null && lastLng != null && lastLocationTime != null) {
            final lastTime = DateTime.tryParse(lastLocationTime);
            if (lastTime != null && DateTime.now().difference(lastTime).inMinutes < 10) {
              // Use cached location if it's less than 10 minutes old
              position = Position(
                latitude: lastLat,
                longitude: lastLng,
                timestamp: lastTime,
                accuracy: 100, // Assume 100m accuracy for cached location
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
              debugPrint("📍 Using cached location: ${position.latitude}, ${position.longitude}");
            }
          }
        }
      }

      // If still no position and not already checked in, do time-only check
      if (position == null && (punchedInTaskId == null || punchedInTaskId.isEmpty)) {
        debugPrint("📍 No location available - doing time-only check for auto check-in");
        await _checkTimeOnlyAutoCheckIn();
        return;
      }
      
      if (position == null) {
        debugPrint("❌ No position available and already checked in - skipping check");
        return;
      }

      // Save current location if we got a fresh GPS reading
      if (position.timestamp.isAfter(DateTime.now().subtract(const Duration(seconds: 30)))) {
        await prefs.setDouble('last_lat', position.latitude);
        await prefs.setDouble('last_lng', position.longitude);
        await prefs.setString('last_location_time', DateTime.now().toIso8601String());
      }

      debugPrint("📍 Using location: ${position.latitude}, ${position.longitude}");
      
      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity == ConnectivityResult.none;
      
      if (isOffline) {
        debugPrint("📴 Device is offline - checking for auto check-in/out");
      }

      // Check if not already punched in and should auto check-in
      if ((punchedInTaskId == null || punchedInTaskId.isEmpty)) {
        await _checkAutoCheckIn(position, isOffline);
      } else {
        // Already punched in - check for auto check-out
        await _checkAutoCheckOut(punchedInTaskId, position, isOffline);
      }

    } catch (e) {
      debugPrint("❌ Location check failed: $e");
    }
  }

  /// Check for time-only auto check-in when location is unavailable
  Future<void> _checkTimeOnlyAutoCheckIn() async {
    if (_cachedTasks.isEmpty) {
      final dbTasks = await DBHelper().getTasks();
      _cachedTasks = dbTasks.map((taskData) => Task.fromMap(taskData)).toList();
      debugPrint("📋 Loaded ${_cachedTasks.length} tasks from local DB for time-only check");
    }

    final now = DateTime.now();
    final todayDate = DateFormat("yyyy-MM-dd").format(now);

    List<int> _toHMS(String time) {
      final parts = time.trim().split(':');
      return [
        int.tryParse(parts[0]) ?? 0,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0
      ];
    }

    for (var task in _cachedTasks) {
      debugPrint("🕐 Time-only check for task: ${task.taskName} (${task.status})");

      // Skip completed tasks
      if (task.status.toLowerCase() == "completed") continue;

      // Skip if auto check-in is disabled
      if (!task.autoCheckin) continue;

      // Check if task is for today
      if (task.date != todayDate) {
        debugPrint("⛔ Task ${task.taskName} is not for today: ${task.date} vs $todayDate");
        continue;
      }

      // Parse time
      final start = _toHMS(task.startTime);
      final end = _toHMS(task.endTime);

      DateTime startDt = DateTime(now.year, now.month, now.day, start[0], start[1], start[2]);
      DateTime endDt = DateTime(now.year, now.month, now.day, end[0], end[1], end[2]);

      // Handle overnight shifts
      if (endDt.isBefore(startDt)) {
        endDt = endDt.add(const Duration(days: 1));
      }

      // Check if we're in the time window (be more lenient - allow check-in if start time has passed)
      if (now.isAfter(startDt) && now.isBefore(endDt)) {
        debugPrint("🎯 Time-based auto check-in triggered for: ${task.taskName} (no location check)");
        
        // Create a fake position at task location for check-in
        final fakePosition = Position(
          latitude: double.tryParse(task.lat) ?? 0.0,
          longitude: double.tryParse(task.longg) ?? 0.0,
          timestamp: DateTime.now(),
          accuracy: 999, // Mark as low accuracy
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        
        final connectivity = await Connectivity().checkConnectivity();
        final isOffline = connectivity == ConnectivityResult.none;
        
        await _performAutoCheckIn(task, fakePosition, isOffline, timeOnlyMode: true);
        return; // Only check in to one task
      } else {
        debugPrint("⛔ Task ${task.taskName} not in time window. Current: $now, Window: $startDt - $endDt");
      }
    }

    debugPrint("ℹ️ No valid tasks for time-only auto check-in");
  }

  /// Check for auto check-in based on time and location
  Future<void> _checkAutoCheckIn(Position position, bool isOffline) async {
    if (_cachedTasks.isEmpty) {
      // Try to load tasks from local database
      final dbTasks = await DBHelper().getTasks();
      _cachedTasks = dbTasks.map((taskData) => Task.fromMap(taskData)).toList();
      debugPrint("📋 Loaded ${_cachedTasks.length} tasks from local DB");
    }

    final now = DateTime.now();
    final todayDate = DateFormat("yyyy-MM-dd").format(now);

    List<int> _toHMS(String time) {
      final parts = time.trim().split(':');
      return [
        int.tryParse(parts[0]) ?? 0,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0
      ];
    }

    List<Map<String, dynamic>> matchedTasks = [];

    for (var task in _cachedTasks) {
      debugPrint("🔍 Checking task: ${task.taskName} (${task.status})");

      // Skip completed tasks
      if (task.status.toLowerCase() == "completed") continue;

      // Skip if auto check-in is disabled
      if (!task.autoCheckin) continue;

      // Check if task is for today
      if (task.date != todayDate) {
        debugPrint("⛔ Task ${task.taskName} is not for today: ${task.date} vs $todayDate");
        continue;
      }

      // ✅ LOCATION CHECK FIRST
      double distance = Geolocator.distanceBetween(
        _toSixDecimals(position.latitude),
        _toSixDecimals(position.longitude),
        double.tryParse(task.lat) ?? 0.0,
        double.tryParse(task.longg) ?? 0.0,
      );

      debugPrint("📏 Distance to task ${task.taskName}: ${distance.toStringAsFixed(1)}m (radius: ${task.radius}m)");

      if (distance > task.radius) {
        debugPrint("⛔ Not on location - Distance: ${distance.toStringAsFixed(1)}m (>${task.radius}m)");
        continue; // Skip this task if not on location
      }

      // Parse time
      final start = _toHMS(task.startTime);
      final end = _toHMS(task.endTime);

      DateTime startDt = DateTime(now.year, now.month, now.day, start[0], start[1], start[2]);
      DateTime endDt = DateTime(now.year, now.month, now.day, end[0], end[1], end[2]);

      // Handle overnight shifts
      if (endDt.isBefore(startDt)) {
        endDt = endDt.add(const Duration(days: 1));
      }

      // ✅ FLEXIBLE TIME CHECK - Allow check-in if:
      // 1. After start time (even if late) and before end time
      if (now.isAfter(endDt)) {
        debugPrint("⛔ Task ${task.taskName} already ended at ${task.endTime}");
        continue;
      }
      
      if (now.isBefore(startDt)) {
        debugPrint("⛔ Too early - Task starts at ${task.startTime}");
        continue;
      }

      // Calculate priority score for intelligent task selection
      int priorityScore = 0;
      
      // Priority 1: Task that has started recently (within 30 minutes)
      final timeSinceStart = now.difference(startDt).inMinutes;
      if (timeSinceStart >= 0 && timeSinceStart <= 30) {
        priorityScore += 100; // High priority for recently started tasks
      }
      
      // Priority 2: High priority tasks get bonus
      if (task.priority.toLowerCase() == 'high') {
        priorityScore += 50;
      }
      
      // Priority 3: Closer location gets higher score (inverse distance)
      priorityScore += (1000 - distance.toInt()).clamp(0, 1000);

      // Within radius and in valid time window
      matchedTasks.add({
        "task": task,
        "distance": distance,
        "startDt": startDt,
        "priorityScore": priorityScore,
        "timeSinceStart": timeSinceStart,
      });
    }

    if (matchedTasks.isEmpty) {
      debugPrint("ℹ️ No valid tasks for auto check-in");
      return;
    }

    // Smart sorting: Priority score first, then distance, then start time
    matchedTasks.sort((a, b) {
      // Primary: Highest priority score wins
      int scoreComp = (b["priorityScore"] as int).compareTo(a["priorityScore"] as int);
      if (scoreComp != 0) return scoreComp;
      
      // Secondary: Closest distance
      int distComp = (a["distance"] as double).compareTo(b["distance"] as double);
      if (distComp != 0) return distComp;
      
      // Tertiary: Earliest start time
      return (a["startDt"] as DateTime).compareTo(b["startDt"] as DateTime);
    });

    Task bestTask = matchedTasks.first["task"];
    double bestDistance = matchedTasks.first["distance"];
    int bestScore = matchedTasks.first["priorityScore"];
    int timeSinceStart = matchedTasks.first["timeSinceStart"];
    
    debugPrint("🎯 Selected task for auto check-in:");
    debugPrint("   Task: ${bestTask.taskName}");
    debugPrint("   Distance: ${bestDistance.toStringAsFixed(1)}m (radius: ${bestTask.radius}m)");
    debugPrint("   Priority Score: $bestScore");
    debugPrint("   Time since start: ${timeSinceStart}m");
    debugPrint("   Found ${matchedTasks.length} eligible tasks");

    await _performAutoCheckIn(bestTask, position, isOffline);
  }

  /// Perform the actual auto check-in
  Future<void> _performAutoCheckIn(Task task, Position position, bool isOffline, {bool timeOnlyMode = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Use default auto check-in image from assets
      final ByteData imageData = await rootBundle.load('assets/images/auto_check_in.jpeg');
      final Directory tempDir = await getTemporaryDirectory();
      final File imageFile = File('${tempDir.path}/auto_check_in.jpeg');
      await imageFile.writeAsBytes(imageData.buffer.asUint8List());

      final DateTime now = DateTime.now();

      if (isOffline) {
        // Save to local database
        final mode = timeOnlyMode ? "(Time-based, No GPS)" : "(Location-based)";
        debugPrint("📴 Saving auto check-in offline for task: ${task.taskName} $mode");
        debugPrint("📅 Exact arrival timestamp: ${now.toIso8601String()}");
        await DBHelper().insertPunchAction({
          'task_id': task.id,
          'type': 'punch-in',
          'lat': _toSixDecimals(position.latitude).toString(),
          'long': _toSixDecimals(position.longitude).toString(),
          'image_path': imageFile.path,
          'timestamp': now.toIso8601String(),
          'remark': timeOnlyMode ? 'Auto Check-in (Time-based, Offline)' : 'Auto Check-in (Offline)',
          'synced': 0,
        });

        // Update local state
        await prefs.setString('punchedInTaskId', task.id);
        await prefs.setString('punchInTime', now.toIso8601String());

        // Trigger callback to start timer in main app
        if (_onAutoCheckInCallback != null) {
          _onAutoCheckInCallback!(task.id, now);
        }

        debugPrint("✅ Auto check-in saved offline for ${task.taskName} $mode");
      } else {
        // Online API call
        final mode = timeOnlyMode ? "(Time-based)" : "(Location-based)";
        debugPrint("🌐 Online auto check-in for ${task.taskName} $mode");
        
        final success = await _sendAutoCheckInToAPI(
          task.id,
          _toSixDecimals(position.latitude).toString(),
          _toSixDecimals(position.longitude).toString(),
        );
        
        if (success) {
          debugPrint("✅ Online auto check-in successful for ${task.taskName}");
          
          // Update local state
          await prefs.setString('punchedInTaskId', task.id);
          await prefs.setString('punchInTime', now.toIso8601String());
          
          // Trigger callback to start timer in main app
          if (_onAutoCheckInCallback != null) {
            _onAutoCheckInCallback!(task.id, now);
          }
        } else {
          debugPrint("⚠️ Online auto check-in failed for ${task.taskName} - API rejected (likely not on location)");
          // Don't save offline or trigger callback for location-based failures
          // The API is more accurate about location validation
        }
      }

    } catch (e) {
      debugPrint("❌ Auto check-in failed: $e");
    }
  }

  /// Check for auto check-out based on distance and time
  Future<void> _checkAutoCheckOut(String taskId, Position position, bool isOffline) async {
    // Find the punched-in task
    Task? punchedTask;
    for (var task in _cachedTasks) {
      if (task.id == taskId) {
        punchedTask = task;
        break;
      }
    }

    if (punchedTask == null) {
      debugPrint("⚠️ Punched-in task not found: $taskId");
      return;
    }

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    
    // Check if punch-in time exists
    final punchInTimeStr = prefs.getString('punchInTime');
    DateTime? punchInTime;
    if (punchInTimeStr != null) {
      punchInTime = DateTime.tryParse(punchInTimeStr);
    }

    bool shouldCheckOut = false;
    String reason = "";

    // Only check time-based checkout (no location restriction for checkout)
    if (punchInTime != null) {
      List<int> _toHMS(String time) {
        final parts = time.trim().split(':');
        return [
          int.tryParse(parts[0]) ?? 0,
          parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
          parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0
        ];
      }

      final endParts = _toHMS(punchedTask.endTime);
      DateTime endTime = DateTime(
        punchInTime.year,
        punchInTime.month,
        punchInTime.day,
        endParts[0],
        endParts[1],
        endParts[2],
      );

      // Handle overnight shifts
      if (endTime.isBefore(punchInTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      if (now.isAfter(endTime)) {
        shouldCheckOut = true;
        reason = "Time check-out (task ended at ${punchedTask.endTime})";
      }
    }

    if (shouldCheckOut) {
      debugPrint("🚪 Auto check-out triggered: $reason");
      await _performAutoCheckOut(punchedTask, position, reason, isOffline);
    }
  }

  /// Perform the actual auto check-out
  Future<void> _performAutoCheckOut(Task task, Position position, String reason, bool isOffline) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // ✅ VALIDATION: Check if user is actually punched in
      final punchedInTaskId = prefs.getString('punchedInTaskId');
      if (punchedInTaskId == null || punchedInTaskId.isEmpty) {
        debugPrint("⛔ Auto checkout cancelled - No active punch-in found");
        return;
      }
      
      // ✅ VALIDATION: Ensure punched-in task matches the current task
      if (punchedInTaskId != task.id) {
        debugPrint("⛔ Auto checkout cancelled - Task mismatch. Punched in: $punchedInTaskId, Current: ${task.id}");
        return;
      }

      // Use default auto check-in image from assets
      final ByteData imageData = await rootBundle.load('assets/images/auto_check_in.jpeg');
      final Directory tempDir = await getTemporaryDirectory();
      final File imageFile = File('${tempDir.path}/auto_check_in.jpeg');
      await imageFile.writeAsBytes(imageData.buffer.asUint8List());

      // Verify the image file was created successfully
      if (!await imageFile.exists()) {
        debugPrint('❌ Failed to create auto_check_in.jpeg at ${imageFile.path}');
        return;
      } else {
        debugPrint('✅ Created auto_check_in.jpeg at ${imageFile.path}');
      }

      final DateTime now = DateTime.now();

      if (isOffline) {
        // Save to local database
        debugPrint("📴 Saving auto check-out offline for task: ${task.taskName}");
        await DBHelper().insertPunchAction({
          'task_id': task.id,
          'type': 'punch-out',
          'lat': position.latitude.toStringAsFixed(4),
          'long': position.longitude.toStringAsFixed(4),
          'image_path': imageFile.path,
          'timestamp': now.toIso8601String(),
          'remark': 'Auto Check-out (Offline) - $reason',
          'synced': 0,
        });

        // Clear punch-in state
        await prefs.remove('punchedInTaskId');
        await prefs.remove('punchInTime');

        debugPrint("✅ Auto check-out saved offline for ${task.taskName}");
      } else {
        // TODO: Implement online API call here if needed
        debugPrint("🌐 Online auto check-out for ${task.taskName}");
      }

    } catch (e) {
      debugPrint("❌ Auto check-out failed: $e");
    }
  }

  /// Update cached tasks
  void updateTasks(List<Task> tasks) {
    _cachedTasks = tasks;
    debugPrint("📋 Updated cached tasks: ${tasks.length} tasks");
  }

  double _toSixDecimals(double value) {
    String three = value.toStringAsFixed(3);
    String six = double.parse(three).toStringAsFixed(6);
    return double.parse(six);
  }

  /// Get pending sync count
  Future<int> getPendingSyncCount() async {
    return await DBHelper().getPendingSyncCount();
  }

  /// Send auto check-in to API
  Future<bool> _sendAutoCheckInToAPI(String taskId, String lat, String lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        debugPrint("⚠️ No auth token found");
        return false;
      }

      const url = 'https://admin.deineputzcrew.de/api/punch-in/';
      
      // Load default auto check-in image
      final ByteData imageData = await rootBundle.load('assets/images/auto_check_in.jpeg');
      final Directory tempDir = await getTemporaryDirectory();
      final File imageFile = File('${tempDir.path}/auto_check_in.jpeg');
      await imageFile.writeAsBytes(imageData.buffer.asUint8List());
      
      // Verify the image file was created successfully
      if (!await imageFile.exists()) {
        debugPrint('❌ Failed to create auto_check_in.jpeg at ${imageFile.path}');
        return false;
      } else {
        debugPrint('✅ Created auto_check_in.jpeg at ${imageFile.path}');
      }
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers['Authorization'] = 'token $token';
      
      request.fields['task_id'] = taskId;
      request.fields['lat'] = lat;
      request.fields['long'] = lng;
      request.fields['auto_checkin'] = 'true';
      request.fields['timestamp'] = DateTime.now().toIso8601String();
      
      // Attach image file
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        imageFile.path,
        filename: 'auto_check_in.jpeg',
      ));
      
      debugPrint("📤 Sending auto check-in API request for task: $taskId");
      debugPrint("📍 Coordinates: $lat, $lng");
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      debugPrint("📱 API Response: ${response.statusCode}");
      debugPrint("📄 Response body: $responseBody");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ API check-in successful");
        return true;
      } else {
        debugPrint("❌ API request failed with status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ Error sending auto check-in to API: $e");
      return false;
    }
  }

  bool get isMonitoring => _isMonitoring;
}

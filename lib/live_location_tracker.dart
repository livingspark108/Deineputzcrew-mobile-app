import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Live location tracking: while a worker is punched in, pings the server
/// with their current GPS position roughly every 30 seconds, so the admin
/// dashboard's live map can show where everyone currently working is.
///
/// Runs via flutter_foreground_task so it keeps working with the app
/// minimized or the screen off (Android: a real foreground service with a
/// persistent notification, as required by Android 8+; iOS: a background
/// task, subject to iOS's own ~30s-every-15-minutes background execution
/// budget — see README limitations).
class LiveLocationTracker {
  static const _prefsTaskIdKey = 'live_tracking_task_id';
  static const int _pingIntervalMs = 30000;

  /// Call once at app startup (before the service is ever started).
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'live_location_tracking',
        channelName: 'Live Location Tracking',
        channelDescription:
            'Shown while you are punched in, so your location can be tracked for attendance.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(_pingIntervalMs),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start pinging location for [taskId] every ~30s. Call right after a
  /// successful punch-in.
  static Future<void> start(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsTaskIdKey, taskId);

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: 501,
      notificationTitle: 'Deineputzcrew — Punched In',
      notificationText: 'Your location is being tracked while you\'re on shift.',
      callback: startLocationTrackingCallback,
    );
  }

  /// Stop pinging. Call right after a successful punch-out (or when no
  /// tasks remain punched in).
  static Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTaskIdKey);
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }
}

/// Entry point for the background isolate — must be a top-level or static
/// function annotated with vm:entry-point.
@pragma('vm:entry-point')
void startLocationTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(_LocationPingTaskHandler());
}

class _LocationPingTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _sendPing();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _sendPing();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  Future<void> _sendPing() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskId = prefs.getString('live_tracking_task_id');
      final token = prefs.getString('token');
      if (taskId == null || taskId.isEmpty || token == null || token.isEmpty) {
        return; // not punched in (or logged out) — nothing to ping for
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      await http.post(
        Uri.parse('https://admin.deineputzcrew.de/api/location-ping/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'token $token',
        },
        body: jsonEncode({
          'task_id': taskId,
          'lat': position.latitude,
          'long': position.longitude,
        }),
      ).timeout(const Duration(seconds: 20));
    } catch (_) {
      // Best-effort: a missed ping isn't worth surfacing to the user; the
      // next 30s tick will simply try again.
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Live location tracking: while a worker is punched in, pings the server
/// with their current GPS position roughly every 30 seconds, so the admin
/// dashboard's live map can show where everyone currently working is.
///
/// Android: driven by flutter_foreground_task — a real foreground service
/// with a persistent notification (as required by Android 8+), whose
/// repeating background isolate calls Geolocator.getCurrentPosition() every
/// tick. This works reliably because the foreground service keeps the
/// process fully alive.
///
/// iOS: flutter_foreground_task's repeating callback is NOT reliable here —
/// even with "Always" location permission granted, iOS treats that callback
/// as a background processing/fetch task, which the OS is free to throttle
/// to roughly once every 15 minutes, independent of permission level. The
/// only OS-sanctioned way to get regular location updates while
/// backgrounded on iOS is a genuine continuous CoreLocation stream started
/// with `allowBackgroundLocationUpdates: true` (requires "Always"
/// permission + `UIBackgroundModes: location` in Info.plist, both already
/// present in this project). Starting that stream keeps the whole Flutter
/// engine alive in the background for as long as the stream is active, so
/// on iOS we drive pings directly from the position stream (throttled to
/// ~30s) instead of going through flutter_foreground_task at all.
class LiveLocationTracker {
  static const _prefsTaskIdKey = 'live_tracking_task_id';
  static const int _pingIntervalMs = 30000;

  static StreamSubscription<Position>? _iosPositionSub;
  static DateTime? _iosLastPingAt;

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

    if (Platform.isIOS) {
      await _startIOSStream();
      return;
    }

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

    if (Platform.isIOS) {
      await _iosPositionSub?.cancel();
      _iosPositionSub = null;
      _iosLastPingAt = null;
      return;
    }

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// iOS-only: start a genuine background-capable CoreLocation stream and
  /// throttle its updates down to one server ping every ~30s.
  static Future<void> _startIOSStream() async {
    // Restarting (e.g. switching tasks while already tracking) — cancel any
    // existing stream first so we don't end up with two subscriptions.
    await _iosPositionSub?.cancel();
    _iosLastPingAt = null;

    _iosPositionSub = Geolocator.getPositionStream(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      ),
    ).listen(
      (position) => _throttledSendPing(position),
      onError: (_) {},
      cancelOnError: false,
    );

    // Send an immediate first ping so the map isn't stale right after
    // punch-in (the stream's first event can take a moment to arrive).
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      _iosLastPingAt = DateTime.now();
      await _sendPingForPosition(position);
    } catch (_) {}
  }

  static void _throttledSendPing(Position position) {
    final now = DateTime.now();
    if (_iosLastPingAt != null &&
        now.difference(_iosLastPingAt!).inMilliseconds < _pingIntervalMs) {
      return;
    }
    _iosLastPingAt = now;
    _sendPingForPosition(position);
  }

  static Future<void> _sendPingForPosition(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taskId = prefs.getString(_prefsTaskIdKey);
      final token = prefs.getString('token');
      if (taskId == null || taskId.isEmpty || token == null || token.isEmpty) {
        return; // not punched in (or logged out) — nothing to ping for
      }

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
      // next update will simply try again.
    }
  }
}

/// Entry point for the background isolate — must be a top-level or static
/// function annotated with vm:entry-point. Android only (see class doc
/// above for why iOS doesn't use this path).
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

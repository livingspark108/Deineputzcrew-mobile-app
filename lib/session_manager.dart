import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'background_task_manager.dart';
import 'l10n/app_localizations.dart';
import 'live_location_tracker.dart';
import 'location_service.dart';
import 'login.dart';

/// Root navigator, so a logout can be triggered from anywhere.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class SessionManager {
  /// Prefs that belong to the device, not the logged-in user.
  static const _keysToKeep = {'consent_accepted', 'consent_audit', 'app_language'};

  static bool _loggingOut = false;

  /// True when the server rejected our token (DRF "Invalid token.").
  static bool isUnauthorized(int statusCode) => statusCode == 401;

  /// Clears the stored session and returns to the login screen.
  static Future<void> forceLogout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      debugPrint('🔒 Token rejected by server - logging out');

      LocationService().stopMonitoring();
      await LiveLocationTracker.stop();
      await BackgroundTaskManager.stopTaskMonitoring();

      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (!_keysToKeep.contains(key)) await prefs.remove(key);
      }

      final navigator = appNavigatorKey.currentState;
      if (navigator == null) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (_) => false,
      );

      final context = navigator.context;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).sessionExpiredSnackbar),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      _loggingOut = false;
    }
  }
}

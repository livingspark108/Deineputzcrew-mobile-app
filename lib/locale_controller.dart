import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

/// App-wide language switch (English / German). Defaults to English.
/// Persisted in SharedPreferences so the choice survives app restarts.
class LocaleController {
  LocaleController._();

  static const _prefsKey = 'app_language';

  static final ValueNotifier<Locale> notifier =
      ValueNotifier<Locale>(const Locale('en'));

  /// Call once at app startup, before runApp, so the saved language is
  /// applied on the very first frame (no flash of the wrong language).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == 'de') {
      notifier.value = const Locale('de');
    }
  }

  static Future<void> setLocale(Locale locale) async {
    notifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// For code with no BuildContext (push notifications, Android foreground
  /// services, background isolates) — reads the saved language straight
  /// from SharedPreferences (works even in a separate background isolate,
  /// unlike [notifier] which only reflects the current app instance's
  /// in-memory state) and returns the matching strings directly.
  static Future<AppLocalizations> currentStrings() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    return lookupAppLocalizations(Locale(code == 'de' ? 'de' : 'en'));
  }
}

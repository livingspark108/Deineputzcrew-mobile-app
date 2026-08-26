import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

const String _prefsKey = 'punch_timezone';

// Only used until the server has ever told us a real timezone (e.g. the
// very first launch before any successful login). Not used once a real
// value has been received — see setPunchTimezone().
const String _fallbackTimezone = 'Europe/Berlin';

bool _tzDataInitialized = false;
String? _cachedTimezone;

/// Must be called once before [punchTimeNow] is used (see main.dart).
/// Loads the IANA timezone database and restores whatever timezone name
/// was last received from the backend (persisted across app restarts).
Future<void> initPunchTimeZone() async {
  if (!_tzDataInitialized) {
    tz_data.initializeTimeZones();
    _tzDataInitialized = true;
  }

  if (_cachedTimezone == null) {
    final prefs = await SharedPreferences.getInstance();
    _cachedTimezone = prefs.getString(_prefsKey);
  }
}

/// Call this whenever an API response includes a `timezone` field (IANA
/// name, e.g. "Europe/Berlin") — login verify, get_user_detail, etc.
/// Persists it so it survives app restarts and offline punches.
Future<void> setPunchTimezone(String? ianaName) async {
  final String? name = (ianaName ?? '').trim().isEmpty ? null : ianaName!.trim();
  if (name == null) return;

  // Validate it's a real IANA name before trusting it — a bad value here
  // would silently break every punch timestamp.
  if (!_tzDataInitialized) {
    tz_data.initializeTimeZones();
    _tzDataInitialized = true;
  }
  try {
    tz.getLocation(name);
  } catch (e) {
    debugPrint('⚠️ Ignoring unknown timezone from API: "$name" ($e)');
    return;
  }

  if (_cachedTimezone == name) return;

  _cachedTimezone = name;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, name);
  debugPrint('🌍 Punch timezone set from API: $name');
}

/// Pulls a `timezone` field out of a decoded API response, checking a few
/// plausible shapes (top-level, or nested under "data"/"user"), and applies
/// it via [setPunchTimezone] if present. Safe to call on any response.
Future<void> applyTimezoneFromApiResponse(Map<String, dynamic> json) async {
  final dynamic value = json['timezone'] ??
      (json['data'] is Map ? (json['data'] as Map)['timezone'] : null) ??
      (json['user'] is Map ? (json['user'] as Map)['timezone'] : null);

  if (value != null) {
    await setPunchTimezone(value.toString());
  }
}

/// The current wall-clock time in whatever timezone the backend has told
/// us to use for this account (falls back to Europe/Berlin only if the
/// server has never sent one yet, e.g. before first login).
///
/// Only use this for the `timestamp` recorded/sent for punch in/out and
/// break in/out actions (both the live API call and the offline queue
/// written to DBHelper.insertPunchAction). Do NOT use it for on-device
/// elapsed-time/stopwatch math (e.g. `DateTime.now().difference(...)`) —
/// that math must keep using the device's own `DateTime.now()` on both
/// sides of the subtraction, since duration between two device clock
/// reads is timezone-independent; mixing this value into a difference
/// against device-local `DateTime.now()` would introduce an error equal
/// to the offset between the device's timezone and the punch timezone.
DateTime punchTimeNow() {
  if (!_tzDataInitialized) {
    // Safety net if initPunchTimeZone() was somehow skipped.
    tz_data.initializeTimeZones();
    _tzDataInitialized = true;
  }

  final location = tz.getLocation(_cachedTimezone ?? _fallbackTimezone);
  final tzNow = tz.TZDateTime.now(location);

  // Return a plain DateTime carrying that zone's wall-clock numbers, so
  // .toIso8601String() keeps the same naive-local format the backend
  // already expects (no 'Z'/offset suffix) — only the value changes.
  return DateTime(
    tzNow.year,
    tzNow.month,
    tzNow.day,
    tzNow.hour,
    tzNow.minute,
    tzNow.second,
    tzNow.millisecond,
    tzNow.microsecond,
  );
}

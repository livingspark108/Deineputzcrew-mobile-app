import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// RULE: every punch-in, punch-out, break-in and break-out timestamp —
/// online and offline, manual and auto — is Germany time (Europe/Berlin),
/// whatever timezone the phone is set to. See docs/PUNCH_TIMEZONE.md.
///
/// Fixed on purpose: it is NOT taken from the API or the device, so a
/// missing/wrong server value or a phone abroad can never change it.
const String kPunchTimezone = 'Europe/Berlin';

bool _tzDataInitialized = false;

void _ensureTzData() {
  if (!_tzDataInitialized) {
    tz_data.initializeTimeZones();
    _tzDataInitialized = true;
  }
}

tz.Location get _punchLocation {
  _ensureTzData();
  return tz.getLocation(kPunchTimezone);
}

/// Call once at startup (see main.dart) — loads the timezone database.
Future<void> initPunchTimeZone() async {
  _ensureTzData();
}

/// Kept for existing call sites. The API's `timezone` field is ignored:
/// punch times are always [kPunchTimezone].
Future<void> setPunchTimezone(String? ianaName) async {
  final name = (ianaName ?? '').trim();
  if (name.isNotEmpty && name != kPunchTimezone) {
    debugPrint(
        '⚠️ API sent timezone "$name" — ignored, punches always use $kPunchTimezone');
  }
}

/// Kept for existing call sites (login verify, user detail). See
/// [setPunchTimezone] — the value is only logged if it differs.
Future<void> applyTimezoneFromApiResponse(Map<String, dynamic> json) async {
  final dynamic value = json['timezone'] ??
      (json['data'] is Map ? (json['data'] as Map)['timezone'] : null) ??
      (json['user'] is Map ? (json['user'] as Map)['timezone'] : null);
  if (value != null) await setPunchTimezone(value.toString());
}

/// The current Germany (Europe/Berlin) wall-clock time, DST included.
///
/// Use this for the `timestamp` of every punch/break action — the live API
/// call AND the offline queue (DBHelper.insertPunchAction / offline_checkins).
/// The result is a plain DateTime carrying Berlin's numbers, so
/// `.toIso8601String()` gives the naive format the backend expects
/// (no 'Z'/offset), e.g. "2026-11-18T05:48:37.059268".
///
/// Do NOT use it for on-device elapsed-time math against `DateTime.now()`
/// (timers) — on a phone outside Germany that's off by the zone gap. To
/// turn a Berlin timestamp back into device time use [parseServerPunchTime].
DateTime punchTimeNow() {
  final tzNow = tz.TZDateTime.now(_punchLocation);
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

/// Converts a punch timestamp from the API (e.g. an attendance's
/// "timestamp") into a device-local [DateTime] that can safely be compared
/// with `DateTime.now()` — e.g. to restore the running work timer.
///
/// The backend stores and returns punch times as naive Berlin wall-clock
/// values (what [punchTimeNow] sends, no offset). Plain `DateTime.parse`
/// would read them as the *device's* local time, so on a phone in another
/// timezone the timer would be off by the difference (India vs Berlin =
/// 4h30). A value that carries an offset/'Z' is already unambiguous and is
/// just converted to local time.
DateTime parseServerPunchTime(String value) {
  final parsed = DateTime.parse(value);
  final hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value.trim());
  if (hasOffset) return parsed.toLocal();

  final inBerlin = tz.TZDateTime(
    _punchLocation,
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
  return DateTime.fromMillisecondsSinceEpoch(inBerlin.millisecondsSinceEpoch);
}

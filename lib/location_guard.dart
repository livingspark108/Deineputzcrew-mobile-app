import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Gate for the attendance actions that record where the employee is:
/// punch-in, punch-out, break-in and break-out.
///
/// Returns true only when Location Services (GPS) are ON and location
/// permission is granted. Otherwise it shows a blocking popup telling the
/// user to turn location on, and returns false — the caller must then abort
/// the action (so nothing is punched without a location).
///
/// The rest of the app stays usable without location (App Review 5.1.5);
/// only these location-dependent actions are blocked.
Future<bool> ensureLocationReady(BuildContext context) async {
  // 1. Location Services (GPS) switched on at the device level.
  bool serviceOn;
  try {
    serviceOn = await Geolocator.isLocationServiceEnabled();
  } catch (_) {
    serviceOn = false;
  }
  if (!serviceOn) {
    await _showLocationDialog(
      context,
      message:
          'Location is turned off. Please turn on Location Services to punch in, punch out, or take a break.',
      openSettings: Geolocator.openLocationSettings,
    );
    return false;
  }

  // 2. App location permission.
  LocationPermission permission;
  try {
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  } catch (_) {
    permission = LocationPermission.denied;
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    await _showLocationDialog(
      context,
      message:
          'This needs location permission. Please allow location access to punch in, punch out, or take a break.',
      openSettings: Geolocator.openAppSettings,
    );
    return false;
  }

  return true;
}

Future<void> _showLocationDialog(
  BuildContext context, {
  required String message,
  required Future<bool> Function() openSettings,
}) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Location required'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(ctx).pop();
            try {
              await openSettings();
            } catch (_) {}
          },
          child: const Text('Turn on location'),
        ),
      ],
    ),
  );
}

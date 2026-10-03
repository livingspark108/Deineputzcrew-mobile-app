import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'l10n/app_localizations.dart';

/// Why a fresh location could not be obtained.
enum LocationFetchError {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationFetchException implements Exception {
  final LocationFetchError error;
  final Object? cause;

  const LocationFetchException(this.error, [this.cause]);

  @override
  String toString() => 'LocationFetchException($error, $cause)';
}

/// Gets the device's *current* position for punch-in.
///
/// Never falls back to getLastKnownPosition() or any saved location. The OS
/// can still hand back a cached fix from getCurrentPosition(), so any fix
/// older than [maxAge] is discarded and a new one is requested until
/// [timeout] runs out.
class FreshLocation {
  static const Duration maxAge = Duration(seconds: 15);

  static Future<Position> get({
    Duration timeout = const Duration(seconds: 25),
    bool requestPermission = true,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFetchException(LocationFetchError.servicesDisabled);
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && requestPermission) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFetchException(
          LocationFetchError.permissionDeniedForever);
    }
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      throw const LocationFetchException(LocationFetchError.permissionDenied);
    }

    final deadline = DateTime.now().add(timeout);
    try {
      while (true) {
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero) {
          throw const LocationFetchException(LocationFetchError.timeout);
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: remaining,
          ),
        );

        final age = DateTime.now().difference(position.timestamp);
        if (age <= maxAge) return position;

        debugPrint(
            '📍 Discarding cached location fix (${age.inSeconds}s old), retrying');
        await Future.delayed(const Duration(seconds: 1));
      }
    } on LocationFetchException {
      rethrow;
    } on TimeoutException catch (e) {
      throw LocationFetchException(LocationFetchError.timeout, e);
    } on LocationServiceDisabledException catch (e) {
      throw LocationFetchException(LocationFetchError.servicesDisabled, e);
    } on PermissionDeniedException catch (e) {
      throw LocationFetchException(LocationFetchError.permissionDenied, e);
    } catch (e) {
      throw LocationFetchException(LocationFetchError.unknown, e);
    }
  }
}

/// True when [error] means the request never reached the server.
bool isNetworkError(Object error) =>
    error is SocketException ||
    error is http.ClientException ||
    error is TimeoutException ||
    error is HandshakeException;

/// Popup explaining why the current location could not be read, with a
/// shortcut to the relevant settings screen where that can fix it.
Future<void> showLocationErrorDialog(
    BuildContext context, LocationFetchException exception) {
  final l10n = AppLocalizations.of(context);

  final String message;
  Future<bool> Function()? openSettings;
  switch (exception.error) {
    case LocationFetchError.servicesDisabled:
      message = l10n.locationErrorServicesDisabled;
      openSettings = Geolocator.openLocationSettings;
      break;
    case LocationFetchError.permissionDenied:
      message = l10n.locationErrorPermissionDenied;
      openSettings = Geolocator.openAppSettings;
      break;
    case LocationFetchError.permissionDeniedForever:
      message = l10n.locationErrorPermissionDeniedForever;
      openSettings = Geolocator.openAppSettings;
      break;
    case LocationFetchError.timeout:
      message = l10n.locationErrorTimeout;
      break;
    case LocationFetchError.unknown:
      message = l10n.locationErrorUnknown(exception.cause.toString());
      break;
  }

  return _showErrorDialog(
    context,
    icon: Icons.location_off,
    title: l10n.locationErrorDialogTitle,
    message: message,
    onOpenSettings: openSettings,
  );
}

/// Popup shown when a punch request fails because there is no internet.
Future<void> showNetworkErrorDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return _showErrorDialog(
    context,
    icon: Icons.wifi_off,
    title: l10n.networkErrorDialogTitle,
    message: l10n.networkErrorDialogBody,
  );
}

Future<void> _showErrorDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  Future<bool> Function()? onOpenSettings,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: Colors.red, size: 28),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 16)),
      actions: [
        if (onOpenSettings != null)
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onOpenSettings();
            },
            child: Text(l10n.dialogOpenSettingsButton),
          ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.dialogOkButton),
        ),
      ],
    ),
  );
}

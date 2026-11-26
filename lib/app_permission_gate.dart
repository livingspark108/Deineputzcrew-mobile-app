import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

/// Requests the permissions the app can use — notifications and location —
/// ONCE on first launch, then always shows the app.
///
/// Per Apple App Review (guidelines 4.5.4 and 5.1.5) notifications and
/// Location Services must be optional: the app has to be fully usable when
/// the user declines them or turns Location Services off. So this no longer
/// blocks any screen. Features that genuinely need location (e.g. punching
/// in) still ask for / check it at the moment they're used; the rest of the
/// app keeps working without it.
class AppPermissionGate extends StatefulWidget {
  final Widget child;

  const AppPermissionGate({super.key, required this.child});

  @override
  State<AppPermissionGate> createState() => _AppPermissionGateState();
}

class _AppPermissionGateState extends State<AppPermissionGate> {
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    // Fire-and-forget: ask for consent but never block on the result.
    _requestOnce();
  }

  Future<void> _requestOnce() async {
    if (_asked) return;
    _asked = true;
    // Notifications — optional. iOS only shows the system prompt the first
    // time; afterwards this just returns the stored choice without nagging.
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted && !status.isPermanentlyDenied) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('⚠️ Notification permission request skipped: $e');
    }
    // Location — optional. Only prompt if it hasn't been decided yet; don't
    // force Location Services on.
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint('⚠️ Location permission request skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

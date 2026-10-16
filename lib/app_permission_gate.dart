import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;

import 'l10n/app_localizations.dart';

/// Hard-stops the whole app until everything it needs is enabled:
///   1. notification permission
///   2. location permission (while-in-use or always)
///   3. location (GPS) switched on in the phone
///
/// Wraps every screen (installed via MaterialApp.builder in main.dart), so
/// no screen can be used while anything is missing. Status is re-checked on
/// launch, every time the app returns to the foreground, whenever location
/// is switched on/off, and every few seconds as a fallback. While blocked,
/// the system permission prompts are shown again automatically each time
/// the app is opened/resumed, and the Allow button asks again (or opens
/// Settings once the phone will no longer show the prompt).
class AppPermissionGate extends StatefulWidget {
  final Widget child;

  const AppPermissionGate({super.key, required this.child});

  @override
  State<AppPermissionGate> createState() => _AppPermissionGateState();
}

class _AppPermissionGateState extends State<AppPermissionGate>
    with WidgetsBindingObserver {
  // null = not checked yet (don't flash the blocker before the first check)
  bool? _notificationsOk;
  bool? _locationPermissionOk;
  bool? _locationServiceOk;

  bool _requesting = false;
  StreamSubscription<ServiceStatus>? _serviceSub;
  Timer? _pollTimer;

  bool get _checked =>
      _notificationsOk != null &&
      _locationPermissionOk != null &&
      _locationServiceOk != null;

  bool get _allOk =>
      _notificationsOk == true &&
      _locationPermissionOk == true &&
      _locationServiceOk == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Location switched on/off from the quick-settings panel doesn't
    // always pause the app, so listen for it directly.
    try {
      _serviceSub = Geolocator.getServiceStatusStream().listen((_) => _check());
    } catch (e) {
      debugPrint('⚠️ Location service stream unavailable: $e');
    }
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_requesting) _check();
    });

    _check(autoAsk: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // System permission dialogs also pause/resume the app; ignore the
    // resume our own request caused, otherwise it would re-prompt forever.
    if (state == AppLifecycleState.resumed && !_requesting) {
      _check(autoAsk: true);
    }
  }

  static bool _notificationAllowed(PermissionStatus s) =>
      s.isGranted || s.isProvisional || s.isLimited;

  static bool _locationAllowed(LocationPermission p) =>
      p == LocationPermission.always || p == LocationPermission.whileInUse;

  Future<void> _check({bool autoAsk = false}) async {
    try {
      final notification = await Permission.notification.status;
      final locationPermission = await Geolocator.checkPermission();
      final locationService = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      setState(() {
        _notificationsOk = _notificationAllowed(notification);
        _locationPermissionOk = _locationAllowed(locationPermission);
        _locationServiceOk = locationService;
      });
    } catch (e) {
      // Never lock the user out because the status check itself failed
      debugPrint('⚠️ Permission check failed: $e');
      if (!mounted) return;
      setState(() {
        _notificationsOk ??= true;
        _locationPermissionOk ??= true;
        _locationServiceOk ??= true;
      });
      return;
    }

    // Declined earlier? Ask again whenever the app is opened/resumed.
    if (autoAsk && !_allOk && !_requesting) {
      await _askAgain(fromButton: false);
    }
  }

  /// Requests every missing permission in turn. From the button, anything
  /// the phone won't prompt for any more is fixed by opening Settings.
  Future<void> _askAgain({required bool fromButton}) async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      // 1. Notifications
      var notification = await Permission.notification.status;
      if (!_notificationAllowed(notification)) {
        if (!notification.isPermanentlyDenied) {
          notification = await Permission.notification.request();
        }
        if (!_notificationAllowed(notification) && fromButton) {
          await openAppSettings();
          return; // re-checked when the user comes back
        }
      }

      // 2. Location permission
      var locationPermission = await Geolocator.checkPermission();
      if (!_locationAllowed(locationPermission)) {
        if (locationPermission != LocationPermission.deniedForever) {
          locationPermission = await Geolocator.requestPermission();
        }
        if (!_locationAllowed(locationPermission) && fromButton) {
          await Geolocator.openAppSettings();
          return;
        }
      }

      // 3. Location (GPS) switched on — apps can't switch it on
      // themselves, only open the phone's location settings.
      if (fromButton && !await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Permission request failed: $e');
    } finally {
      if (mounted) setState(() => _requesting = false);
      await _check();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_checked && !_allOk)
          Positioned.fill(child: _buildBlocker(context)),
      ],
    );
  }

  Widget _buildBlocker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: const Color(0xFFF6F7F9),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_outline,
                      size: 42, color: Colors.black),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.permissionGateTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.permissionGateMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
                _requirementRow(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.permissionGateNotificationsTitle,
                  subtitle: l10n.permissionGateNotificationsSubtitle,
                  ok: _notificationsOk == true,
                ),
                _requirementRow(
                  icon: Icons.location_on_outlined,
                  title: l10n.permissionGateLocationPermissionTitle,
                  subtitle: l10n.permissionGateLocationPermissionSubtitle,
                  ok: _locationPermissionOk == true,
                ),
                _requirementRow(
                  icon: Icons.gps_fixed,
                  title: l10n.permissionGateLocationServiceTitle,
                  subtitle: l10n.permissionGateLocationServiceSubtitle,
                  ok: _locationServiceOk == true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _requesting ? null : () => _askAgain(fromButton: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _requesting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            l10n.permissionGateAllowButton,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.permissionGateSettingsHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _requirementRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool ok,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok ? const Color(0xFF28A745) : const Color(0xFFDC3545),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 12.5, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? const Color(0xFF28A745) : const Color(0xFFDC3545),
          ),
        ],
      ),
    );
  }
}

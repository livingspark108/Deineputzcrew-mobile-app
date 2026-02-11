import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';
import 'privacypolicy.dart';
import 'terms.dart';
import 'notification_service.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool ageConfirmed = false;
  bool privacyAccepted = false;
  bool notificationAccepted = false;
  bool locationDeviceIdAccepted = false;

  bool get allAccepted =>
      ageConfirmed &&
      privacyAccepted &&
      notificationAccepted &&
      locationDeviceIdAccepted;

  /// 🧾 SAVE CONSENT + AUDIT LOG + REQUEST NOTIFICATION PERMISSION
  Future<void> _continue() async {
    final prefs = await SharedPreferences.getInstance();

    final auditLog = {
      "consent_version": "v1.0",
      "age_confirmed": ageConfirmed,
      "privacy_accepted": privacyAccepted,
      "notification_accepted": notificationAccepted,
      "location_device_id_accepted": locationDeviceIdAccepted,
      "platform": Theme.of(context).platform.name,
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    };

    await prefs.setBool('consent_accepted', true);
    await prefs.setString('consent_audit', jsonEncode(auditLog));

    // ✅ REQUEST NOTIFICATION PERMISSION IF USER ACCEPTED IN CONSENT
    if (notificationAccepted) {
      await _requestNotificationPermission();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  /// 🔔 REQUEST NOTIFICATION PERMISSION
  Future<void> _requestNotificationPermission() async {
    try {
      print('🔔 Requesting notification permission after consent...');
      
      // Use NotificationService to request permissions
      final granted = await NotificationService.requestNotificationPermissions();
      
      if (granted) {
        print('✅ Notification permissions granted by user');
      } else {
        print('⚠️ Notification permissions denied by user');
        // Optionally show a message to the user
      }
    } catch (e) {
      print('⚠️ Error requesting notification permission: $e');
    }
  }

  // CONSENT CARD
  Widget _consentCard({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
    List<InlineSpan>? links,
  }) {
    return Semantics(
      label: title,
      hint: "Double tap to ${value ? 'disable' : 'enable'}",
      checked: value,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!value), // ENTIRE CARD CLICKABLE
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value ? Colors.black : Colors.transparent,
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// iOS-style animated checkbox
              AnimatedScale(
                scale: value ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 160),
                child: Checkbox(
                  value: value,
                  onChanged: (v) => onChanged(v ?? false),
                  activeColor: Colors.black,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),

                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: description),
                          if (links != null) ...links,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      /// Prevent back button bypass
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      const Text(
                        "Before You Continue",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Please review and confirm the following to use this app.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// 🔞 AGE CONFIRMATION
                      _consentCard(
                        title: "Age Confirmation",
                        description:
                            "You must be at least 18 years old to use this app.",
                        value: ageConfirmed,
                        onChanged: (v) =>
                            setState(() => ageConfirmed = v ?? false),
                      ),

                      /// 🔐 PRIVACY + TERMS
                      _consentCard(
                        title: "Your Privacy Matters",
                        description:
                            "We only collect data required to provide our services. ",
                        value: privacyAccepted,
                        onChanged: (v) =>
                            setState(() => privacyAccepted = v ?? false),
                        links: [
                          TextSpan(
                            text: "Privacy Policy",
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: " and "),
                          TextSpan(
                            text: "Terms & Conditions",
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TermsConditionsScreen(),
                                  ),
                                );
                              },
                          ),
                          const TextSpan(text: "."),
                        ],
                      ),

                      /// 🔔 NOTIFICATIONS
                      _consentCard(
                        title: "Allow Notifications",
                        description:
                            "Receive important updates and service alerts. "
                            "You can disable notifications anytime in settings.",
                        value: notificationAccepted,
                        onChanged: (v) => setState(
                            () => notificationAccepted = v ?? false),
                      ),

                      /// 📍 LOCATION + DEVICE ID
                      _consentCard(
                        title: "Location & Device Information",
                        description:
                            "We collect your device identifier and, if you allow, "
                            "your approximate location to improve security, "
                            "prevent fraud, and deliver location-based services.\n\n"
                            "Your location is not tracked continuously and is "
                            "never shared or sold. You can change this permission "
                            "anytime in your device settings.",
                        value: locationDeviceIdAccepted,
                        onChanged: (v) => setState(
                            () => locationDeviceIdAccepted = v ?? false),
                      ),
                    ],
                  ),
                ),
              ),

              /// 🚀 CONTINUE BUTTON (STICKY)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: allAccepted ? _continue : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: allAccepted
                          ? Colors.black
                          : Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

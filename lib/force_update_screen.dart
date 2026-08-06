import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_metadata.dart';

const Color _kBrandOrange = Color(0xFFFF7A1A);

/// Non-dismissible "you must update" screen. Used both pre-login (from the
/// Login screen) and post-login (wrapping the whole authenticated app), so
/// there is no path through the app on an unsupported version.
class ForceUpdateScreen extends StatelessWidget {
  final String? androidDownloadLink;
  final String? iosTestflightLink;
  final String? iosDiawiLink;

  const ForceUpdateScreen({
    super.key,
    this.androidDownloadLink,
    this.iosTestflightLink,
    this.iosDiawiLink,
  });

  void _handleUpdateButtonPressed(BuildContext context) {
    if (AppMetadata.isIOS) {
      // Open directly — no TestFlight/Diawi picker. TestFlight is preferred;
      // Diawi is only used as a fallback if no TestFlight link was sent.
      final String? iosLink =
          (iosTestflightLink != null && iosTestflightLink!.trim().isNotEmpty)
              ? iosTestflightLink
              : iosDiawiLink;
      _launchUpdateUrl(context, iosLink);
      return;
    }

    _launchUpdateUrl(context, androidDownloadLink);
  }

  Future<void> _launchUpdateUrl(BuildContext context, String? url) async {
    if (url == null || url.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Update link is not available.')),
      );
      return;
    }

    try {
      Uri uri = Uri.tryParse(url) ?? Uri();
      if (uri.toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid update link.')),
        );
        return;
      }

      // For Play Store links, try both https and market schemes
      if (url.contains('play.google.com')) {
        // Try market:// scheme first (native Play Store app)
        final marketUri = Uri.parse('market://details?id=com.diveinpuits');

        try {
          if (await canLaunchUrl(marketUri)) {
            await launchUrl(marketUri, mode: LaunchMode.externalApplication);
            return;
          }
        } catch (e) {
          debugPrint('🔗 Market URI failed: $e');
        }
      }

      // Try launching the URL as-is
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // If canLaunchUrl fails, still try launching it
        // Some URLs might still work even if canLaunchUrl returns false
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('🔗 Launch URL failed: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Unable to open update link: ${e.toString()}')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('🔗 Update URL error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening update link: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildReasonRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kBrandOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 2),

                        // 🖼️ Small brand mark, keeps this screen recognizable
                        // as "our app", not a generic system error page.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/app_logo.jpg',
                            height: 56,
                            width: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // 🔶 Alert badge
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: _kBrandOrange.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: const BoxDecoration(
                                color: _kBrandOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.system_update_alt_rounded,
                                color: Colors.white,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        const Text(
                          'Update Required',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'A newer version of Deine Putzcrew is available and required to keep using the app.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),

                        // 📋 Why-card — same neutral card style used on the
                        // login screen's "access is limited" notice.
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildReasonRow(
                                Icons.bug_report_outlined,
                                'Bug fixes and stability improvements',
                              ),
                              _buildReasonRow(
                                Icons.security_rounded,
                                'Important security updates',
                              ),
                              _buildReasonRow(
                                Icons.lock_clock_outlined,
                                'Punch in/out will stay disabled until you update',
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 3),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => _handleUpdateButtonPressed(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.system_update_alt_rounded, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  'Update Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppMetadata.isIOS
                              ? "You'll be redirected to TestFlight to install the update."
                              : "You'll be redirected to the Play Store to install the update.",
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Colors.black38,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

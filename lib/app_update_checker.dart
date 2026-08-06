import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_metadata.dart';

class AppUpdateInfo {
  final bool updateRequired;
  final String? androidDownloadLink;
  final String? iosTestflightLink;
  final String? iosDiawiLink;

  const AppUpdateInfo({
    required this.updateRequired,
    this.androidDownloadLink,
    this.iosTestflightLink,
    this.iosDiawiLink,
  });
}

/// Unauthenticated version check, safe to call before login.
/// Returns null (fail-open) on network/parse errors so a flaky connection
/// never blocks the login screen — only an explicit `update_required: true`
/// from the server triggers the forced update screen.
Future<AppUpdateInfo?> checkAppUpdateRequired() async {
  try {
    final uri = Uri.parse(
      'https://admin.deineputzcrew.de/api/app-version',
    ).replace(queryParameters: {
      'platform': AppMetadata.mobileType,
      'app_version': AppMetadata.appVersion,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    if (body['success'] != true) return null;

    final data = body['data'];
    if (data == null) return null;

    final bool updateRequired =
        data['update_required'] == true || data['update_required'] == 'true';

    return AppUpdateInfo(
      updateRequired: updateRequired,
      androidDownloadLink: data['android_download_link']?.toString(),
      iosTestflightLink: data['ios_testflight_link']?.toString(),
      iosDiawiLink: data['ios_diawi_link']?.toString(),
    );
  } catch (e) {
    debugPrint('⚠️ App update check failed (ignored, fail-open): $e');
    return null;
  }
}

import 'dart:io';

class AppMetadata {
  static const String appVersion = '3.3';

  static String get mobileType => Platform.isIOS ? 'ios' : 'android';

  static bool get isIOS => Platform.isIOS;
}

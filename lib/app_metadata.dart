import 'dart:io';

class AppMetadata {
  static const String appVersion = '2.5';

  static String get mobileType => Platform.isIOS ? 'ios' : 'android';

  static bool get isIOS => Platform.isIOS;
}

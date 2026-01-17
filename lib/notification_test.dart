import 'dart:io';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class NotificationTest {
  static Future<void> runDiagnostics() async {
    print('\n🔍 === NOTIFICATION DIAGNOSTICS ===');
    
    // Get status
    Map<String, dynamic> status = await NotificationService.getNotificationStatus();
    print('📊 Status Report:');
    status.forEach((key, value) {
      print('   $key: $value');
    });
    
    // Platform specific tests
    if (Platform.isIOS) {
      print('\n📱 iOS Specific Tests:');
      await _testIOSNotifications();
    } else {
      print('\n🤖 Android Specific Tests:');
      await _testAndroidNotifications();
    }
    
    // Try to get token manually
    print('\n🎯 Manual Token Generation Test:');
    String? manualToken = await NotificationService.manualTokenGeneration();
    if (manualToken != null) {
      print('✅ Manual token generation successful');
      print('🎯 Token: ${manualToken.substring(0, 20)}...');
    } else {
      print('❌ Manual token generation failed');
    }
    
    print('\n🔍 === DIAGNOSTICS COMPLETE ===\n');
  }
  
  static Future<void> _testIOSNotifications() async {
    try {
      print('🔍 Testing iOS notification setup...');
      
      // Check if we're in simulator
      if (kDebugMode) {
        print('⚠️ Running in debug mode - APNS limitations expected');
      }
      
      // Try to get current token
      String? currentToken = await NotificationService.getToken();
      if (currentToken != null) {
        print('✅ Current FCM token available');
      } else {
        print('⚠️ No FCM token available (normal in development)');
      }
      
    } catch (e) {
      print('❌ iOS notification test failed: $e');
    }
  }
  
  static Future<void> _testAndroidNotifications() async {
    try {
      print('🔍 Testing Android notification setup...');
      
      // Try to get current token
      String? currentToken = await NotificationService.getToken();
      if (currentToken != null) {
        print('✅ Android FCM token available');
        print('🎯 Token: ${currentToken.substring(0, 20)}...');
      } else {
        print('❌ Android FCM token not available');
      }
      
    } catch (e) {
      print('❌ Android notification test failed: $e');
    }
  }
  
  static void printTroubleshootingGuide() {
    print('\n📚 === TROUBLESHOOTING GUIDE ===');
    
    if (Platform.isIOS) {
      print('iOS Push Notification Issues:');
      print('');
      print('🔧 Common Solutions:');
      print('1. Test on physical iOS device (not simulator)');
      print('2. Upload APNs authentication key to Firebase Console:');
      print('   - Go to Firebase Console > Project Settings > Cloud Messaging');
      print('   - Upload your APNs auth key (.p8 file)');
      print('   - Set key ID and Team ID');
      print('3. Check iOS capabilities in Xcode:');
      print('   - Enable "Push Notifications" capability');
      print('   - Enable "Background Modes" -> "Remote notifications"');
      print('4. Verify Bundle ID matches Firebase configuration');
      print('5. Check entitlements file has correct aps-environment');
      print('');
      print('⚠️ Development Mode Limitations:');
      print('- APNS tokens may not be available immediately');
      print('- Simulator may not receive push notifications');
      print('- Debug builds use development APNs environment');
      print('');
      print('✅ Production Checklist:');
      print('- Upload production APNs key to Firebase');
      print('- Test with release builds');
      print('- Verify on physical devices');
    } else {
      print('Android Push Notification Issues:');
      print('');
      print('🔧 Common Solutions:');
      print('1. Check google-services.json is in android/app/');
      print('2. Verify package name matches Firebase configuration');
      print('3. Enable notification permissions for Android 13+');
      print('4. Check Firebase project has correct SHA fingerprints');
    }
    
    print('\n📚 === GUIDE COMPLETE ===\n');
  }
}
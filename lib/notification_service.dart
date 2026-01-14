import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static FirebaseMessaging? _firebaseMessaging;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) {
      print('🔄 NotificationService already initialized');
      return;
    }

    try {
      print('🔥 Starting Firebase initialization...');
      
      // Skip Firebase initialization for web due to compatibility issues
      if (kIsWeb) {
        print('🌐 Web platform detected - skipping Firebase initialization');
        _isInitialized = true;
        return;
      }
      
      // Initialize Firebase if not already done
      if (Firebase.apps.isEmpty) {
        print('🔥 Initializing Firebase for the first time...');
        
        // Use firebase_options for cross-platform compatibility
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('✅ Firebase Core initialized');
      } else {
        print('✅ Firebase already initialized');
      }
      
      _firebaseMessaging = FirebaseMessaging.instance;
      print('✅ FirebaseMessaging instance created');

      // Request permissions for both iOS and Android
      print('📱 Requesting notification permissions...');
      
      // For Android 13+ (API 33+), request notification permission first
      if (Platform.isAndroid) {
        print('🤖 Android detected, checking notification permission...');
        PermissionStatus status = await Permission.notification.status;
        print('📋 Current notification permission status: $status');
        
        if (status.isDenied || status.isPermanentlyDenied) {
          print('🔔 Requesting notification permission for Android...');
          PermissionStatus newStatus = await Permission.notification.request();
          print('📋 New notification permission status: $newStatus');
          
          if (newStatus.isPermanentlyDenied) {
            print('⚠️ Notification permission permanently denied');
            print('💡 User needs to enable notifications manually in Settings');
          } else if (newStatus.isDenied) {
            print('⚠️ Notification permission denied');
          } else if (newStatus.isGranted) {
            print('✅ Android notification permission granted');
          }
        } else {
          print('✅ Android notification permission already granted');
        }
      }
      
      // Debug: Check app configuration
      print('🔍 App Configuration:');
      print('   Debug Mode: ${kDebugMode}');
      print('   Profile Mode: ${kProfileMode}');
      print('   Release Mode: ${kReleaseMode}');
      print('   Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
      if (Platform.isIOS) {
        print('   Bundle ID: com.diveinpuits.diveinpuits');
      } else {
        print('   Package: com.diveinpuits');
      }
      
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (Platform.isIOS) {
        print('✅ iOS notification permissions: ${settings.authorizationStatus}');
        
        // Check if we have the right APNs configuration
        if (kDebugMode) {
          print('🛠️ Running in DEBUG mode - using Development APNs');
        } else if (kReleaseMode) {
          print('🚀 Running in RELEASE mode - using Production APNs');
        } else {
          print('📊 Running in PROFILE mode');
        }
      } else {
        print('✅ Android notification permissions: ${settings.authorizationStatus}');
        print('📱 Android SDK: ${Platform.version}');
      }

      // Initialize local notifications
      await _initializeLocalNotifications();
      print('✅ Local notifications initialized');

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Get FCM token with retry
      await _getAndLogToken();

      _isInitialized = true;
      print('✅ NotificationService initialization complete');

    } catch (e) {
      print('❌ Error initializing notifications: $e');
      print('📋 Stack trace: ${StackTrace.current}');
      // Don't throw error, just log it
      _isInitialized = false;
    }
  }

  static Future<void> _getAndLogToken() async {
    try {
      // For iOS, wait for APNS token first
      if (Platform.isIOS) {
        print('📱 iOS detected, waiting for APNS token...');
        String? apnsToken = await _firebaseMessaging!.getAPNSToken();
        
        if (apnsToken == null) {
          print('⏳ APNS token not available, waiting...');
          // Wait up to 3 seconds for APNS token (reduced from 10)
          int attempts = 0;
          while (apnsToken == null && attempts < 3) {
            await Future.delayed(Duration(seconds: 1));
            apnsToken = await _firebaseMessaging!.getAPNSToken();
            attempts++;
            print('⏳ APNS token attempt $attempts: $apnsToken');
          }
        }
        
        if (apnsToken != null) {
          print('✅ APNS token available: ${apnsToken.substring(0, 10)}...');
        } else {
          print('⚠️ APNS token still not available after 3 seconds');
          print('💡 In DEBUG mode, this is normal. Proceeding with FCM token generation anyway...');
        }
      }
      
      // Try to get FCM token regardless of APNS token status
      try {
        String? token = await _firebaseMessaging!.getToken();
        print('🎯 FCM Token (first attempt): $token');
        
        if (token == null || token.isEmpty) {
          print('🔄 FCM Token is null, trying force refresh...');
          // Force refresh by deleting and regenerating
          try {
            await _firebaseMessaging!.deleteToken();
            await Future.delayed(Duration(milliseconds: 1500));
            token = await _firebaseMessaging!.getToken();
            print('🔄 FCM Token (after refresh): $token');
          } catch (refreshError) {
            print('⚠️ Token refresh failed: $refreshError');
          }
          
          if (token == null || token.isEmpty) {
            print('⚠️ FCM Token still null - this is expected in DEBUG mode');
            print('💡 App will use device UDID as fallback for device identification');
          } else {
            print('✅ FCM Token generated after refresh!');
          }
        } else {
          print('✅ FCM Token successfully generated: ${token.substring(0, 20)}...');
        }
      } catch (fcmError) {
        print('⚠️ FCM Token generation failed: $fcmError');
        print('💡 This is common in development mode - using device UDID as fallback');
      }
    } catch (e) {
      print('❌ Error getting FCM token during initialization: $e');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification when app is in foreground
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data.toString(),
    );
  }

  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message opened app: ${message.messageId}');
    // Handle navigation or other actions when notification is tapped
  }

  static void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<String?> getToken() async {
    try {
      // If not initialized, try to initialize
      if (!_isInitialized || _firebaseMessaging == null) {
        print('🔄 Firebase not ready, initializing...');
        await initialize();
        
        // If still not initialized after attempt, return null
        if (!_isInitialized || _firebaseMessaging == null) {
          print('❌ Firebase initialization failed, returning null token');
          return null;
        }
        
        // Wait a moment for Firebase to be fully ready after initialization
        await Future.delayed(Duration(milliseconds: 500));
      }
      
      // For iOS, ensure APNS token is available
      if (Platform.isIOS) {
        print('📱 iOS: Checking APNS token availability...');
        String? apnsToken = await _firebaseMessaging!.getAPNSToken();
        
        if (apnsToken == null) {
          print('⏳ APNS token not ready, waiting...');
          // Wait up to 8 seconds for APNS token with progressive delay
          int attempts = 0;
          while (apnsToken == null && attempts < 8) {
            await Future.delayed(Duration(seconds: attempts + 1)); // Progressive delay
            try {
              apnsToken = await _firebaseMessaging!.getAPNSToken();
              if (apnsToken != null) {
                print('✅ APNS token available after ${attempts + 1} attempts');
                break;
              }
            } catch (e) {
              print('⚠️ APNS token check failed (attempt ${attempts + 1}): $e');
            }
            attempts++;
            print('⏳ APNS attempt ${attempts}/8...');
          }
          
          if (apnsToken == null) {
            print('⚠️ APNS token still not available after 8 attempts');
            print('ℹ️ This is normal in development/simulator mode');
            print('ℹ️ For production, ensure APNs auth key is uploaded to Firebase Console');
          } else {
            print('✅ APNS token is now available');
          }
        } else {
          print('✅ APNS token already available');
        }
      }
      
      final token = await _firebaseMessaging!.getToken();
      print('📱 FCM Token retrieved: $token');
      
      // If token is null, try one more time with a delay
      if (token == null || token.isEmpty) {
        print('⚠️ Token is null/empty, trying again...');
        await Future.delayed(Duration(seconds: 3));
        final retryToken = await _firebaseMessaging!.getToken();
        print('🔄 Retry FCM Token: $retryToken');
        
        if (retryToken == null || retryToken.isEmpty) {
          print('❌ FCM token still null after retry');
          print('ℹ️ This may be due to:');
          print('  - Development/simulator environment (normal)');
          print('  - Missing APNs configuration in Firebase Console');
          print('  - Network connectivity issues');
        }
        
        return retryToken;
      }
      
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      
      // Provide helpful error messages
      if (e.toString().contains('apns-token-not-set')) {
        print('💡 APNS token not set - this is expected in development mode');
        print('💡 For production: Upload APNs auth key in Firebase Console');
        print('💡 App will work with device ID instead of FCM token');
      } else if (e.toString().contains('network')) {
        print('💡 Network error - check internet connection');
      }
      
      return null;
    }
  }

  static Future<String?> refreshToken() async {
    try {
      if (_firebaseMessaging == null) {
        print('FirebaseMessaging not initialized, initializing now...');
        await initialize();
      }
      
      await _firebaseMessaging?.deleteToken();
      final token = await _firebaseMessaging?.getToken();
      print('FCM Token refreshed: $token');
      return token;
    } catch (e) {
      print('Error refreshing FCM token: $e');
      return null;
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging?.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging?.unsubscribeFromTopic(topic);
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  
  // You can show a local notification here if needed
  // Note: This runs in an isolate, so UI operations are limited
}
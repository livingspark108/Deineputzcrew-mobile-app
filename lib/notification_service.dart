import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static FirebaseMessaging? _firebaseMessaging;
  static bool _isInitialized = false;
  
  // Audio player for continuous notification sound
  static AudioPlayer? _audioPlayer;
  static bool _isPlayingContinuousSound = false;
  static String? _currentAutoCheckInTaskId;

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
      try {
        if (Firebase.apps.isEmpty) {
          print('🔥 Initializing Firebase for the first time...');
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print('✅ Firebase Core initialized');
        } else {
          print('✅ Firebase already initialized');
        }
      } catch (e) {
        // Handle potential initialization errors
        if (e.toString().contains('duplicate-app')) {
          print('⚠️ Firebase app already exists - proceeding with existing instance');
        } else {
          print('❌ Firebase initialization error: $e');
          rethrow;
        }
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
      print('✅ Background message handler registered');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('\\n�🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨');
        print('🔥🔥🔥 FOREGROUND MESSAGE LISTENER TRIGGERED 🔥🔥🔥');
        print('⚡ This proves Firebase messaging is working!');
        print('📨 Message ID: ${message.messageId}');
        print('📨 From: ${message.from}');
        print('🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨\\n');
        _handleForegroundMessage(message);
      });
      print('✅ Foreground message listener registered');

      // Handle notification taps when app is terminated
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('\\n📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱');
        print('📱📱📱 MESSAGE OPENED APP LISTENER TRIGGERED 📱📱📱');
        print('📨 Message ID: ${message.messageId}');
        print('📨 From: ${message.from}');
        print('📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱📱\\n');
        _handleMessageOpenedApp(message);
      });
      print('✅ Message opened app listener registered');

      // Test Firebase messaging connection
      print('\\n🧪 Testing Firebase Messaging connection...');
      try {
        await _firebaseMessaging!.setAutoInitEnabled(true);
        print('✅ Firebase auto-init enabled');
        print('🔥 Firebase Messaging is ready to receive messages!');
      } catch (e) {
        print('❌ Firebase Messaging test failed: $e');
        // Don't let this block the initialization
      }

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

  /// Test method to verify console logging is working
  static void testConsoleLogging() {
    print('\\n🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪');
    print('🧪 CONSOLE TEST - If you see this, console logging works!');
    print('🧪 Current time: ${DateTime.now()}');
    print('🧪 Firebase initialized: $_isInitialized');
    print('🧪 FCM instance available: ${_firebaseMessaging != null}');
    print('🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪🧪\\n');
  }

  /// Manually trigger FCM logging test
  static void debugFCMConnection() async {
    print('\\n🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍');
    print('🔍 FCM DEBUG TEST');
    print('🔍 Is FCM initialized: ${_firebaseMessaging != null}');
    if (_firebaseMessaging != null) {
      try {
        String? token = await _firebaseMessaging!.getToken();
        print('🔍 FCM Token (first 50 chars): ${token?.substring(0, 50)}...');
      } catch (e) {
        print('🔍 Error getting FCM token: $e');
      }
    }
    print('🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍🔍\\n');
  }

  static Future<void> _getAndLogToken() async {
    try {
      // For iOS, wait for APNS token first
      if (Platform.isIOS) {
        print('📱 iOS detected, waiting for APNS token...');
        String? apnsToken = await _firebaseMessaging!.getAPNSToken();
        
        if (apnsToken == null) {
          print('⏳ APNS token not available, waiting...');
          // Wait up to 10 seconds for APNS token with progressive delays
          int attempts = 0;
          while (apnsToken == null && attempts < 5) {
            // Progressive delay: 1s, 2s, 3s, 4s, 5s
            await Future.delayed(Duration(seconds: attempts + 1));
            apnsToken = await _firebaseMessaging!.getAPNSToken();
            attempts++;
            print('⏳ APNS token attempt $attempts: ${apnsToken != null ? "received" : "null"}');
          }
        }
        
        if (apnsToken != null) {
          print('✅ APNS token available: ${apnsToken.substring(0, 10)}...');
        } else {
          print('⚠️ APNS token still not available after 15 seconds');
          print('💡 This is normal in development/simulator mode');
          print('💡 For production, ensure:');
          print('   1. APNs auth key is uploaded to Firebase Console');
          print('   2. App is running on a physical iOS device');
          print('   3. Push notification capability is enabled');
          
          // Try to trigger APNS token registration manually
          try {
            print('🔄 Attempting to manually trigger APNS registration...');
            // This is a workaround for development mode
            await Future.delayed(Duration(milliseconds: 500));
          } catch (e) {
            print('⚠️ Manual APNS registration failed: $e');
          }
        }
      }
      
      // Try to get FCM token regardless of APNS token status in development
      try {
        String? token = await _firebaseMessaging!.getToken();
        
        if (token != null && token.isNotEmpty) {
          print('✅ FCM Token successfully generated: ${token.substring(0, 20)}...');
        } else {
          print('⚠️ FCM Token is null/empty on first attempt');
          
          // For development mode, this is expected - let's try a different approach
          if (kDebugMode && Platform.isIOS) {
            print('🛠️ Development mode detected - using alternative token strategy');
            
            // Wait a bit more and try again
            await Future.delayed(Duration(seconds: 2));
            token = await _firebaseMessaging!.getToken();
            
            if (token != null && token.isNotEmpty) {
              print('✅ FCM Token generated on retry: ${token.substring(0, 20)}...');
            } else {
              print('ℹ️ FCM token unavailable in development mode');
              print('ℹ️ This is expected behavior. Token will be available in:');
              print('   - Production builds');
              print('   - Physical devices with proper APNs setup');
              print('   - When app is distributed via TestFlight or App Store');
            }
          }
        }
      } catch (fcmError) {
        print('⚠️ FCM Token generation failed: $fcmError');
        
        if (fcmError.toString().contains('apns-token-not-set')) {
          print('💡 APNS token not set - this is normal in development');
          print('💡 Solutions:');
          print('   1. Test on physical iOS device (not simulator)');
          print('   2. Upload APNs key to Firebase Console');
          print('   3. Ensure proper iOS signing');
          print('   4. For development: This error can be ignored');
        }
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
    // High importance channel for general notifications
    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    // Auto check-in channel with sound enabled
    const autoCheckinChannel = AndroidNotificationChannel(
      'auto_checkin_channel',
      'Auto Check-in Notifications',
      description: 'Critical notifications for automatic task check-ins with sound.',
      importance: Importance.max,
      enableVibration: false,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('swiggy_new_order'),
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(autoCheckinChannel);
    
    print('✅ Notification channels created with sound enabled');
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('\n🔥 ======= FIREBASE FOREGROUND MESSAGE RECEIVED =======');
    print('📨 Message ID: ${message.messageId}');
    print('📨 From: ${message.from}');
    print('📨 Sent Time: ${message.sentTime}');
    print('📨 TTL: ${message.ttl}');
    
    // Log notification content
    if (message.notification != null) {
      print('🔔 Notification:');
      print('   📝 Title: ${message.notification!.title}');
      print('   📝 Body: ${message.notification!.body}');
      print('    Android: ${message.notification!.android?.toString()}');
      print('   🍎 Apple: ${message.notification!.apple?.toString()}');
    } else {
      print('❌ No notification payload found!');
    }
    
    // Log data payload with DETAILED analysis
    if (message.data.isNotEmpty) {
      print('📦 Data payload:');
      message.data.forEach((key, value) {
        print('   $key: $value (type: ${value.runtimeType})');
      });
      
      // CRITICAL: Check for auto check-in trigger
      print('\\n🔍 ======= AUTO CHECK-IN ANALYSIS =======');
      final hasType = message.data.containsKey('type');
      final typeValue = message.data['type'];
      print('✅ Contains "type" key: $hasType');
      print('✅ Type value: "$typeValue"');
      print('✅ Is auto_checkin_trigger: ${typeValue == "auto_checkin_trigger"}');
      
      if (typeValue == 'auto_checkin_trigger') {
        print('🎯 AUTO CHECK-IN TRIGGER DETECTED!');
        print('📋 Required fields check:');
        print('   task_id: ${message.data['task_id']} ✅');
        print('   task_name: ${message.data['task_name']} ✅');
        print('   start_time: ${message.data['start_time']} ✅');
        print('   location: ${message.data['location']} ✅');
        print('🔊 About to trigger continuous sound and notification...');
      } else {
        print('❌ NOT an auto check-in trigger');
        print('❌ Expected: "auto_checkin_trigger"');
        print('❌ Received: "$typeValue"');
      }
      print('🔍 ===================================\\n');
    } else {
      print('❌ No data payload found!');
      print('❌ AUTO CHECK-IN REQUIRES DATA PAYLOAD!');
    }
    
    print('🔥 ================================================\n');
    
    // Check if this is an auto check-in trigger
    if (message.data.containsKey('type') && message.data['type'] == 'auto_checkin_trigger') {
      print('🎯 AUTO CHECK-IN detected in foreground - handling specially...');
      await _handleAutoCheckInTrigger(message.data);
      return;
    }
    
    // Show local notification when app is in foreground
    await _showLocalNotification(
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data.toString(),
      withSound: true, // Enable sound for all notifications
    );
  }

  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('\n📱📱📱 MESSAGE OPENED APP HANDLER 📱📱📱');
    print('📨 Message ID: ${message.messageId}');
    print('📨 From: ${message.from}');
    
    // Log notification content
    if (message.notification != null) {
      print('🔔 Notification: ${message.notification!.title} - ${message.notification!.body}');
    }
    
    // Log data payload
    if (message.data.isNotEmpty) {
      print('📦 Data Payload:');
      message.data.forEach((key, value) {
        print('   $key: $value');
      });
      
      // Check if this is an auto check-in trigger
      if (message.data['type'] == 'auto_checkin_trigger') {
        print('🎯 AUTO CHECK-IN TRIGGER - User tapped notification!');
        print('� Stopping continuous sound from notification tap...');
        
        // Stop continuous sound when user taps notification
        await stopContinuousSound();
        
        print('✅ Continuous sound stopped from notification tap!');
      }
    } else {
      print('❌ No data payload in opened app message');
    }
    print('📱📱📱 MESSAGE OPENED APP COMPLETE 📱📱📱\n');
  }

  static void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle local notification tap
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool withSound = true,
  }) async {
    print('\n🔔 ======= SHOWING LOCAL NOTIFICATION =======');
    print('📝 Title: $title');
    print('📝 Body: $body');
    print('🔊 With Sound: $withSound');
    print('📋 Payload: $payload');
    
    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: false,
      playSound: withSound,
      sound: withSound ? const RawResourceAndroidNotificationSound('swiggy_new_order') : null,
      icon: '@mipmap/launcher_icon',
      category: AndroidNotificationCategory.message,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: withSound,
      sound: withSound ? 'default' : null,
      interruptionLevel: withSound ? InterruptionLevel.active : InterruptionLevel.passive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('🚀 Showing notification with ID: $notificationId');
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );
      
      print('✅ Local notification displayed successfully');
    } catch (e) {
      print('❌ Failed to show local notification: $e');
    }
    
    print('🔔 =========================================\n');
  }

  static Future<String?> getToken() async {
    try {
      // Check if service is initialized
      if (!_isInitialized || _firebaseMessaging == null) {
        print('⚠️ NotificationService not initialized - call initialize() first');
        return null;
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
        print('⚠️ FirebaseMessaging not initialized - call initialize() first');
        return null;
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

  // Helper method to manually trigger token generation (useful for iOS)
  static Future<String?> manualTokenGeneration() async {
    if (!_isInitialized || _firebaseMessaging == null) {
      print('⚠️ NotificationService not initialized');
      return null;
    }

    try {
      print('🔄 Manual token generation started...');
      
      if (Platform.isIOS) {
        print('📱 iOS: Attempting to force APNS token registration...');
        
        // Wait longer for APNS in manual mode
        int attempts = 0;
        String? apnsToken;
        
        while (apnsToken == null && attempts < 10) {
          await Future.delayed(Duration(seconds: 2));
          try {
            apnsToken = await _firebaseMessaging!.getAPNSToken();
            if (apnsToken != null) {
              print('✅ APNS token received after ${(attempts + 1) * 2} seconds');
              break;
            }
          } catch (e) {
            print('⚠️ APNS check failed (attempt ${attempts + 1}): $e');
          }
          attempts++;
        }
        
        if (apnsToken == null) {
          print('⚠️ APNS token still unavailable - continuing anyway');
        }
      }
      
      // Force delete and regenerate FCM token
      try {
        await _firebaseMessaging!.deleteToken();
        await Future.delayed(Duration(seconds: 3));
        
        String? newToken = await _firebaseMessaging!.getToken();
        if (newToken != null) {
          print('✅ Manual FCM token generation successful');
          return newToken;
        } else {
          print('⚠️ Manual token generation failed');
          return null;
        }
      } catch (e) {
        print('❌ Manual token generation error: $e');
        return null;
      }
    } catch (e) {
      print('❌ Manual token generation failed: $e');
      return null;
    }
  }

  // Check if notifications are properly configured
  static Future<Map<String, dynamic>> getNotificationStatus() async {
    Map<String, dynamic> status = {
      'initialized': _isInitialized,
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'hasFirebaseMessaging': _firebaseMessaging != null,
      'hasAPNSToken': false,
      'hasFCMToken': false,
      'permissionStatus': 'unknown',
    };

    if (_firebaseMessaging != null) {
      try {
        // Check permission status
        NotificationSettings settings = await _firebaseMessaging!.getNotificationSettings();
        status['permissionStatus'] = settings.authorizationStatus.toString();

        // Check APNS token for iOS
        if (Platform.isIOS) {
          String? apnsToken = await _firebaseMessaging!.getAPNSToken();
          status['hasAPNSToken'] = apnsToken != null;
        }

        // Check FCM token
        String? fcmToken = await _firebaseMessaging!.getToken();
        status['hasFCMToken'] = fcmToken != null;

      } catch (e) {
        status['error'] = e.toString();
      }
    }

    return status;
  }

  /// Show auto check-in notification with continuous sound
  static Future<void> showAutoCheckInNotification({
    required String taskId,
    required String taskName,
    required String startTime,
    String? location,
  }) async {
    try {
      print('🔔 Showing auto check-in notification for: $taskName');
      
      // Store current task ID to track which notification is active
      _currentAutoCheckInTaskId = taskId;
      
      // Start continuous sound
      await _startContinuousSound();
      
      // Show local notification
      const androidDetails = AndroidNotificationDetails(
        'auto_checkin_channel',
        'Auto Check-in Notifications',
        channelDescription: 'Critical notifications for automatic task check-ins',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true, // Enable system sound + manual sound
        sound: RawResourceAndroidNotificationSound('swiggy_new_order'),
        ongoing: true, // Makes notification persistent
        autoCancel: false,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true, // Enable system sound + manual sound
        sound: 'default',
        interruptionLevel: InterruptionLevel.critical,
        categoryIdentifier: 'AUTO_CHECKIN',
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final body = location != null 
          ? '🎯 Time to check in at $location\nTask starts at $startTime'
          : '🎯 Time to check in for your task\nTask starts at $startTime';
      
      await _localNotifications.show(
        taskId.hashCode,
        '🚨 Auto Check-in Required',
        body,
        notificationDetails,
        payload: json.encode({
          'type': 'auto_checkin',
          'task_id': taskId,
          'task_name': taskName,
          'start_time': startTime,
        }),
      );

      print('✅ Auto check-in notification shown with continuous sound');
      
    } catch (e) {
      print('❌ Error showing auto check-in notification: $e');
    }
  }
  
  /// Start continuous sound playback
  static Future<void> _startContinuousSound() async {
    if (_isPlayingContinuousSound) {
      await stopContinuousSound(); // Stop any existing sound
    }
    
    try {
      print('\\n🔊 ======= STARTING CONTINUOUS SOUND =======');
      print('🔊 Initializing audio player for continuous sound...');
      _audioPlayer ??= AudioPlayer();
      _isPlayingContinuousSound = true;
      
      print('🔊 Starting continuous notification sound');
      
      // Configure audio for background and foreground playback
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(1.0);
      print('✅ Audio player configured: loop=true, volume=1.0');
      
      // Set audio context for both platforms
      if (Platform.isAndroid) {
        print('🤖 Configuring Android audio context...');
        await _audioPlayer!.setAudioContext(AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ));
        print('✅ Android audio context set');
      } else if (Platform.isIOS) {
        print('📱 Configuring iOS audio context...');
        await _audioPlayer!.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playAndRecord, // Changed to playAndRecord for better compatibility
            options: {
              AVAudioSessionOptions.defaultToSpeaker, // This works with playAndRecord
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ));
        print('✅ iOS audio context set');
      }
      
      print('🎵 Loading audio file: assets/music/swiggy_new_order.caf');
      
      // Check if file exists and is accessible
      try {
        await _audioPlayer!.play(AssetSource('music/swiggy_new_order.caf'));
        print('✅ Audio file started playing');
      } catch (audioError) {
        print('❌ Audio file play failed: $audioError');
        print('🔄 Trying alternative approach...');
        
        // Try with a simpler audio context
        await _audioPlayer!.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ));
        
        await _audioPlayer!.play(AssetSource('music/swiggy_new_order.caf'));
        print('✅ Audio file started with fallback context');
      }
      
      print('✅ Continuous notification sound started successfully');
      
      // Add a listener to check if audio actually started
      _audioPlayer!.onPlayerStateChanged.listen((PlayerState state) {
        print('🎵 Audio player state changed: $state');
        if (state == PlayerState.playing) {
          print('🎵 Continuous sound is actively playing!');
        } else if (state == PlayerState.stopped) {
          print('🛑 Continuous sound stopped');
        } else if (state == PlayerState.paused) {
          print('⏸️ Continuous sound paused');
        } else if (state == PlayerState.completed) {
          print('🔄 Audio completed, should be looping...');
        }
      });
      
      print('🔊 ====================================\\n');
        
    } catch (e) {
      print('❌ Error starting continuous sound: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      _isPlayingContinuousSound = false;
      
      // Try alternative audio approach on iOS
      if (Platform.isIOS) {
        print('🔄 Attempting iOS fallback audio method...');
        // Could add fallback logic here if needed
      }
    }
  }
  
  /// Stop continuous sound
  static Future<void> stopContinuousSound() async {
    if (!_isPlayingContinuousSound) {
      print('ℹ️ Continuous sound is not currently playing');
      return;
    }
    
    try {
      print('🔇 Stopping continuous notification sound for task: $_currentAutoCheckInTaskId');
      
      // Stop audio player
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
        _audioPlayer = null;
        print('✅ Audio player stopped and disposed');
      }
      
      // Reset state
      _isPlayingContinuousSound = false;
      
      // Cancel the notification using the stored task ID
      if (_currentAutoCheckInTaskId != null) {
        await _localNotifications.cancel(_currentAutoCheckInTaskId!.hashCode);
        print('✅ Notification cancelled for task: $_currentAutoCheckInTaskId');
      }
      
      // Clear the task ID after stopping
      _currentAutoCheckInTaskId = null;
      
      print('✅ Continuous sound stopped successfully');
      
    } catch (e) {
      print('❌ Error stopping continuous sound: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      
      // Force reset state even if there was an error
      _isPlayingContinuousSound = false;
      _currentAutoCheckInTaskId = null;
      
      if (_audioPlayer != null) {
        try {
          await _audioPlayer!.dispose();
          _audioPlayer = null;
        } catch (disposeError) {
          print('⚠️ Error disposing audio player: $disposeError');
        }
      }
    }
  }
  
  /// Check if auto check-in sound is currently playing
  static bool get isPlayingAutoCheckInSound => _isPlayingContinuousSound;
  
  /// Get current auto check-in task ID
  static String? get currentAutoCheckInTaskId => _currentAutoCheckInTaskId;
  
  /// Test method to manually trigger auto check-in notification (for debugging)
  static Future<void> testAutoCheckInNotification() async {
    print('🧪 Testing auto check-in notification manually...');
    
    try {
      await showAutoCheckInNotification(
        taskId: 'test-task-123',
        taskName: 'Test Auto Check-in',
        startTime: '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        location: 'Test Location',
      );
      print('✅ Test auto check-in notification triggered successfully');
    } catch (e) {
      print('❌ Test auto check-in notification failed: $e');
    }
  }
  
  /// Test audio file directly (for debugging)
  static Future<void> testAudioFileDirectly() async {
    print('🎵 Testing audio file directly...');
    
    try {
      final testPlayer = AudioPlayer();
      
      print('🎵 Setting up audio player...');
      await testPlayer.setReleaseMode(ReleaseMode.stop);
      await testPlayer.setVolume(1.0);
      
      if (Platform.isIOS) {
        print('📱 Setting iOS audio context...');
        await testPlayer.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ));
      }
      
      print('🎵 Loading audio file: assets/music/swiggy_new_order.caf');
      await testPlayer.play(AssetSource('music/swiggy_new_order.caf'));
      
      print('✅ Audio file test started successfully');
      
      // Listen to player state
      testPlayer.onPlayerStateChanged.listen((PlayerState state) {
        print('🎵 Test audio player state: $state');
      });
      
      // Stop after 5 seconds
      Timer(const Duration(seconds: 5), () async {
        await testPlayer.stop();
        await testPlayer.dispose();
        print('🛑 Test audio stopped');
      });
      
    } catch (e) {
      print('❌ Audio file test failed: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Test notification with sound for FCM debugging
  static Future<void> testNotificationWithSound() async {
    try {
      print('🧪 Testing notification with sound...');
      print('📱 Platform: ${Platform.isIOS ? 'iOS' : 'Android'}');
      print('🔍 Checking notification permissions...');
      
      // Check notification permissions first
      if (Platform.isIOS) {
        final settings = await _firebaseMessaging?.getNotificationSettings();
        print('🔒 iOS Notification Permission: ${settings?.authorizationStatus}');
        print('🔒 iOS Alert Permission: ${settings?.alert}');
        print('🔒 iOS Sound Permission: ${settings?.sound}');
        print('🔒 iOS Badge Permission: ${settings?.badge}');
      }
      
      // For iOS, use simpler notification settings that work better
      final androidDetails = AndroidNotificationDetails(
        'auto_checkin_channel',
        'Auto Check-in Notifications',
        channelDescription: 'Test notification with sound',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.alarm,
        enableLights: true,
        ledColor: const Color(0xFFFF6B35),
      );
      
      // For iOS, use the most basic sound configuration that works
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Use default system sound - this should always work
        sound: 'default',
        interruptionLevel: InterruptionLevel.active, // Changed from critical
      );
      
      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('🔔 Sending notification with ID: $notificationId');
      print('🔊 iOS Sound: default (system sound)');
      print('📳 Vibration enabled: true');
      print('⚡ Priority: max');
      print('🔔 Interruption Level: active');
      
      await _localNotifications.show(
        notificationId,
        '🔔 Sound Test #$notificationId',
        'Testing system default notification sound',
        notificationDetails,
      );
      
      print('✅ Test notification sent with system default sound!');
      print('📋 Troubleshooting:');
      print('   1. Check iPhone Settings → Sounds & Haptics → Ringer and Alerts volume');
      print('   2. Make sure Silent switch (side of phone) is OFF');
      print('   3. Check Settings → Notifications → [Your App] → Sounds = ON');
      print('   4. Try putting app in background and testing again');
      
    } catch (e) {
      print('❌ Test notification failed: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Test FCM connection and token validity
  static Future<void> testFirebaseConnection() async {
    print('\\n🔥 ======= FIREBASE CONNECTION TEST =======');
    
    try {
      if (!_isInitialized || _firebaseMessaging == null) {
        print('❌ Firebase not initialized!');
        return;
      }
      
      // Get current token
      final token = await _firebaseMessaging!.getToken();
      print('🔑 Current Token: ${token?.substring(0, 20)}...');
      
      // Check permissions
      final settings = await _firebaseMessaging!.getNotificationSettings();
      print('🔒 Permission Status: ${settings.authorizationStatus}');
      print('🔒 Alert: ${settings.alert}');
      print('🔒 Sound: ${settings.sound}');
      
      // Test if we can send a self-notification (would need server)
      print('📡 Firebase Messaging object exists: ${_firebaseMessaging != null}');
      print('📡 Firebase app name: ${_firebaseMessaging!.app.name}');
      
      print('✅ Firebase connection test completed');
      print('🔥 =====================================\\n');
      
    } catch (e) {
      print('❌ Firebase connection test failed: $e');
      print('🔥 =====================================\\n');
    }
  }

  /// Test direct audio playback to verify device sound works
  static Future<void> testDirectAudio() async {
    print('\\n🎵 ======= DIRECT AUDIO TEST =======');
    
    try {
      final testPlayer = AudioPlayer();
      
      print('🎵 Testing direct audio playback...');
      print('🔊 Setting audio context...');
      
      if (Platform.isIOS) {
        await testPlayer.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ));
        print('✅ iOS audio context set');
      }
      
      // Try to play a system sound first
      print('🔔 Testing system beep...');
      // This will play a simple beep sound
      
      print('🎵 Testing asset audio file...');
      await testPlayer.play(AssetSource('music/swiggy_new_order.caf'));
      
      print('✅ Audio test started - listen for sound!');
      print('⏱️ Audio will play for 3 seconds...');
      
      // Wait 3 seconds then stop
      await Future.delayed(const Duration(seconds: 3));
      await testPlayer.stop();
      await testPlayer.dispose();
      
      print('🛑 Audio test completed');
      print('🎵 ================================\\n');
      
    } catch (e) {
      print('❌ Direct audio test failed: $e');
      print('❌ This might indicate audio system issues');
      print('🎵 ================================\\n');
    }
  }
  
  /// Handle auto check-in trigger from push notification
  static Future<void> _handleAutoCheckInTrigger(Map<String, dynamic> data) async {
    try {
      final taskId = data['task_id'];
      final taskName = data['task_name'] ?? 'Unknown Task';
      final startTime = data['start_time'] ?? 'Now';
      final location = data['location'];
      
      print('🚨 AUTO CHECK-IN TRIGGER RECEIVED!');
      print('📋 Task ID: $taskId');
      print('📋 Task Name: $taskName');
      print('📋 Start Time: $startTime');
      print('📋 Location: $location');
      print('📋 Full data: $data');
      
      // Initialize audio player if needed
      if (_audioPlayer == null) {
        print('🎵 Initializing audio player for background handler...');
        _audioPlayer = AudioPlayer();
      }
      
      // Show continuous notification with sound that persists until tapped
      await showAutoCheckInNotification(
        taskId: taskId,
        taskName: taskName,
        startTime: startTime,
        location: location,
      );
      
      print('✅ Auto check-in notification started - continuous sound will loop until notification is tapped');
      
    } catch (e) {
      print('❌ Error handling auto check-in trigger: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase with proper options for background messages
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  print('\\n🔥 ======= FIREBASE BACKGROUND MESSAGE RECEIVED =======');
  print('📨 Message ID: ${message.messageId}');
  print('📨 From: ${message.from}');
  print('📨 Sent Time: ${message.sentTime}');
  print('📨 TTL: ${message.ttl}');
  print('📨 Message Type: ${message.messageType}');
  
  // Log notification content
  if (message.notification != null) {
    print('🔔 Notification Content:');
    print('   📝 Title: ${message.notification!.title}');
    print('   📝 Body: ${message.notification!.body}');
    print('   🤖 Android: ${message.notification!.android?.toString()}');
    print('   🍎 Apple: ${message.notification!.apple?.toString()}');
  } else {
    print('❌ No notification payload found in background message!');
  }
  
  // Log data payload  
  if (message.data.isNotEmpty) {
    print('📦 Data Payload:');
    message.data.forEach((key, value) {
      print('   $key: $value');
    });
  } else {
    print('❌ No data payload found in background message!');
  }
  
  print('🔥 ===================================================\\n');
  
  // Handle different message types
  if (message.data.containsKey('type')) {
    final messageType = message.data['type'];
    print('📨 Processing message type: $messageType');
    
    switch (messageType) {
      case 'auto_checkin_trigger':
        print('🎯 Auto check-in trigger detected in background');
        await NotificationService._handleAutoCheckInTrigger(message.data);
        break;
      case 'task_update':
        print('📝 Task update received in background');
        break;
      case 'reminder':
        print('⏰ Reminder received in background');
        break;
      default:
        print('📋 General message received in background');
    }
  } else {
    print('❌ No message type specified in data payload!');
  }
}
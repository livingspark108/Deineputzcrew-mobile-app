import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';

import 'home.dart';
import 'consent_screen.dart';
import 'login.dart';
import 'notification_service.dart';
import 'background_task_manager.dart';

/// 🔔 Local Notifications
final FlutterLocalNotificationsPlugin notificationsPlugin =
FlutterLocalNotificationsPlugin();

/// 🔔 Background FCM handler (TOP LEVEL ONLY)
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
// }

/// 🔥 MAIN
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔔 Local notifications (legacy support)
  await _initLocalNotifications();

  /// 🔔 Initialize NotificationService (Firebase + modern notifications)
  try {
    await NotificationService.initialize();
    print('✅ NotificationService initialized in main()');
  } catch (e) {
    print('⚠️ NotificationService initialization failed: $e');
  }

  /// 📱 Initialize Background Task Manager
  try {
    await BackgroundTaskManager.initialize();
    print('✅ BackgroundTaskManager initialized in main()');
  } catch (e) {
    print('⚠️ BackgroundTaskManager initialization failed: $e');
  }

  runApp(const MyApp());
}

/// 🔔 Local Notifications Init (SAFE)
Future<void> _initLocalNotifications() async {
  try {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS notifications initialization
    const DarwinInitializationSettings darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint("🔔 Notification tapped");
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
    );

    final androidPlugin =
    notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  } catch (e) {
    print('Error initializing notifications: $e');
  }
}

/// 🔔 Show foreground notification
Future<void> showLocalNotification(String title, String body) async {
  const AndroidNotificationDetails androidDetails =
  AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
    macOS: iosDetails,
  );

  await notificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
  );
}

/// 🔥 App Root
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

/// 🌑 Splash Screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // _initFCM();
    _navigate();
  }

  /// 🔔 SAFE FCM INIT
  /*
  Future<void> _initFCM() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    final prefs = await SharedPreferences.getInstance();

    /// Android 13+ permission
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    /// ⚠️ SAFE TOKEN FETCH (NO CRASH)
    String? token;
    try {
      token = await messaging.getToken();
    } catch (e) {
      debugPrint("⚠️ FCM token error: $e");
    }

    if (token != null && token.isNotEmpty) {
      await prefs.setString('fcm_token', token);
      debugPrint("🔥 FCM Token saved");
    }

    /// 🔄 Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await prefs.setString('fcm_token', newToken);
    });

    /// 🔔 Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        showLocalNotification(
          notification.title ?? '',
          notification.body ?? '',
        );
      }
    });

    /// 📲 Notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint("📲 Notification clicked");
    });
  }
  */

  /// 🔄 Navigation
  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    //=== concent accept
    final consentAccepted = prefs.getBool('consent_accepted') ?? false;

    if (!mounted) return;
    
    late Widget nextScreen;
    if (!consentAccepted) {
      /// 🔐 FIRST TIME → Consent Mandatory
      nextScreen = ConsentScreen();
    } else if (token == null || token.isEmpty) {
      /// 🔑 No login
      nextScreen = LoginScreen();
    } else {
      /// 🏠 Logged in
      nextScreen = const MainApp();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );

    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) =>
    //     token == null || token.isEmpty
    //         ? LoginScreen()
    //         : const MainApp(),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          "Welcome!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

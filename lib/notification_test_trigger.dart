import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';

class NotificationTestTrigger extends StatefulWidget {
  const NotificationTestTrigger({Key? key}) : super(key: key);

  @override
  State<NotificationTestTrigger> createState() => _NotificationTestTriggerState();
}

class _NotificationTestTriggerState extends State<NotificationTestTrigger> {
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
    _debugFirebaseSetup();
  }

  Future<void> _debugFirebaseSetup() async {
    print('\\n🔍 ======= FIREBASE HANDLER DEBUG =======');
    print('🔍 Checking if Firebase message handlers are properly set up...');
    
    try {
      // Check if NotificationService is initialized
      final token = await NotificationService.getToken();
      if (token != null) {
        print('✅ Firebase initialized - token available');
      } else {
        print('❌ Firebase token is null - initialization issue!');
      }
      
      print('🔍 App is currently in FOREGROUND state');
      print('🔍 If FCM notification arrives, it should trigger foreground handler');
      print('🔍 If you see notification but no logs, check:');
      print('   1. App might be in background when notification arrives');
      print('   2. Notification permissions might cause system handling');
      print('   3. FCM payload structure might be incorrect');
      
    } catch (e) {
      print('❌ Firebase debug check failed: $e');
    }
    print('🔍 =====================================\\n');
  }

  Future<void> _loadFCMToken() async {
    try {
      final token = await NotificationService.getToken();
      setState(() {
        _fcmToken = token;
      });
      print('🔑 Current FCM Token: $token');
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Test the exact notification that you received
  Future<void> _testExactNotification() async {
    print('🧪 Testing exact notification payload that was received...');
    
    // This is the exact payload you received
    final testData = {
      "type": "auto_checkin_trigger",
      "user_id": 77,
      "task_id": "d9c98812-26a7-4250-9e7d-48c340a12cf5",
      "task_name": "ReinigungD",
      "start_time": "14:57:00",
      "location": "Cyber City",
      "dry_run": false,
      "timestamp": "2026-01-17T14:14:39.881Z"
    };

    try {
      await NotificationService.showAutoCheckInNotification(
        taskId: testData['task_id'] as String,
        taskName: testData['task_name'] as String,
        startTime: testData['start_time'] as String,
        location: testData['location'] as String,
      );
      print('✅ Exact notification test completed - check if music is playing!');
    } catch (e) {
      print('❌ Exact notification test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Check-in Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FCM Token Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔑 Current FCM Token:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _fcmToken ?? 'Loading...',
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (_fcmToken != null) {
                        await Clipboard.setData(ClipboardData(text: _fcmToken!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ FCM Token copied!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // IMMEDIATE TEST BUTTON
            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton.icon(
                onPressed: () async {
                  print('🚨🚨🚨 IMMEDIATE LOCAL NOTIFICATION TEST 🚨🚨🚨');
                  await NotificationService.testNotificationWithSound();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔔 LOCAL TEST - Check if sound/vibration worked!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                icon: const Icon(Icons.volume_up, size: 32),
                label: const Text(
                  '🚨 IMMEDIATE TEST: Local Ring',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            const Icon(
              Icons.alarm,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),
            const Text(
              'Auto Check-in Notification Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'This will test the exact notification payload you received:\n\n'
              '• Task: ReinigungD\n'
              '• Time: 14:57:00\n'
              '• Location: Cyber City\n'
              '• Should play continuous music until stopped',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _testExactNotification,
                icon: const Icon(Icons.play_arrow, size: 28),
                label: const Text(
                  'Test Auto Check-in Notification',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await NotificationService.stopContinuousSound();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🔇 Auto check-in sound stopped')),
                  );
                },
                icon: const Icon(Icons.stop),
                label: const Text('Stop Sound'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Direct test buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await NotificationService.testNotificationWithSound();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🔔 Testing notification with sound - check if it rings!')),
                      );
                    },
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Test Ring'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await NotificationService.testAudioFileDirectly();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎵 Testing audio file directly - check console')),
                      );
                    },
                    icon: const Icon(Icons.music_note),
                    label: const Text('Test Audio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await NotificationService.testFirebaseConnection();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🔥 Firebase connection test - check console!')),
                      );
                    },
                    icon: const Icon(Icons.wifi),
                    label: const Text('Test Firebase'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await NotificationService.testVibrationDirectly();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📳 Testing vibration - check console')),
                      );
                    },
                    icon: const Icon(Icons.vibration),
                    label: const Text('Test Vibration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔧 Debug Steps:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Tap "Test Auto Check-in Notification"\n'
                    '2. Listen for continuous music playing\n'
                    '3. Check notification in notification tray\n'
                    '4. Vibration should occur every 3 seconds\n'
                    '5. Use "Stop Sound" to stop the music',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
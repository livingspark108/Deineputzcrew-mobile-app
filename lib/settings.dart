import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'changepassword.dart';
import 'db_helper.dart';
import 'login.dart';
import 'notification_test_trigger.dart';
import 'notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _name = "";
  String _employeeInfo = "";
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString("username") ?? "User";
      _employeeInfo = prefs.getString("employee_info") ?? "EMPLOYEE";
    });
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    Color? iconColor,
    Color? textColor,
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isLogout ? Colors.red.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.black54),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor ?? Colors.black,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {

          },
        ),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Row(
              children: [

                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _employeeInfo,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text("General",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),

            _buildListTile(
              context: context,
              icon: Icons.refresh,
              title: "Change password",
              iconColor: Colors.black,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.notifications_active,
              title: "🔔 Notification Test Screen",
              iconColor: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationTestTrigger(),
                  ),
                );
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.volume_up,
              title: "🚨 QUICK TEST: Local Ring",
              iconColor: Colors.red,
              onTap: () async {
                print('🚨 QUICK LOCAL NOTIFICATION TEST FROM SETTINGS');
                try {
                  await NotificationService.testNotificationWithSound();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔔 Local notification sent - check if sound played!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Test failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.wifi,
              title: "🔥 Test Firebase Connection",
              iconColor: Colors.blue,
              onTap: () async {
                print('🔥 FIREBASE CONNECTION TEST FROM SETTINGS');
                try {
                  await NotificationService.testFirebaseConnection();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔥 Firebase test completed - check console logs!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Firebase test failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.bug_report,
              title: '🧪 Test Console Logging',
              iconColor: Colors.purple,
              onTap: () {
                print('🧪 Manual console test from settings screen');
                NotificationService.testConsoleLogging();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🧪 Console test triggered - check your console/terminal!'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.network_check,
              title: '🔍 Debug FCM Connection',
              iconColor: Colors.indigo,
              onTap: () {
                print('🔍 Manual FCM debug test from settings screen');
                NotificationService.debugFCMConnection();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔍 FCM debug test triggered - check your console!'),
                    backgroundColor: Colors.indigo,
                  ),
                );
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.notification_add,
              title: '📢 Test DEFAULT iOS Sound',
              iconColor: Colors.orange,
              onTap: () async {
                print('📢 TESTING DEFAULT iOS NOTIFICATION SOUND');
                try {
                  await _localNotifications.show(
                    999999,
                    '📢 DEFAULT SOUND TEST',
                    'This uses default iOS notification sound',
                    const NotificationDetails(
                      iOS: DarwinNotificationDetails(
                        presentAlert: true,
                        presentBadge: true,
                        presentSound: true,
                        sound: null, // Use default iOS sound
                        interruptionLevel: InterruptionLevel.active,
                      ),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📢 Default sound notification sent! Did you hear it?'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e) {
                  print('❌ Default notification failed: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Default notification failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.volume_up,
              title: '🎵 Test CUSTOM iOS Sound',
              iconColor: Colors.deepOrange,
              onTap: () async {
                print('🎵 TESTING CUSTOM iOS NOTIFICATION SOUND');
                try {
                  await _localNotifications.show(
                    888888,
                    '🎵 CUSTOM SOUND TEST',
                    'This should use swiggy_new_order.caf',
                    const NotificationDetails(
                      iOS: DarwinNotificationDetails(
                        presentAlert: true,
                        presentBadge: true,
                        presentSound: true,
                        sound: 'swiggy_new_order.caf', // Custom sound file
                        interruptionLevel: InterruptionLevel.critical,
                      ),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎵 Custom sound notification sent! Hear swiggy sound?'),
                      backgroundColor: Colors.deepOrange,
                    ),
                  );
                } catch (e) {
                  print('❌ Custom sound notification failed: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Custom sound failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.music_note,
              title: "🎵 Test Direct Audio",
              iconColor: Colors.purple,
              onTap: () async {
                print('🎵 DIRECT AUDIO TEST FROM SETTINGS');
                try {
                  await NotificationService.testDirectAudio();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎵 Audio test completed - did you hear sound?'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Audio test failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.loop,
              title: "🔊 Test Continuous Sound (Swiggy)",
              iconColor: Colors.deepOrange,
              onTap: () async {
                print('🔊 TESTING CONTINUOUS SWIGGY SOUND FROM SETTINGS');
                try {
                  // This should start the continuous swiggy new order sound
                  final testData = {
                    "task_id": "test-123",
                    "task_name": "Test Task",
                    "start_time": "now",
                    "location": "Test Location"
                  };
                  
                  await NotificationService.showAutoCheckInNotification(
                    taskId: testData['task_id'] as String,
                    taskName: testData['task_name'] as String,
                    startTime: testData['start_time'] as String,
                    location: testData['location'] as String,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔊 Continuous sound started - should hear swiggy music looping!'),
                      backgroundColor: Colors.deepOrange,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Continuous sound failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.stop,
              title: "🛑 Stop Continuous Sound",
              iconColor: Colors.red,
              onTap: () async {
                print('🛑 STOPPING CONTINUOUS SOUND FROM SETTINGS');
                try {
                  await NotificationService.stopContinuousSound();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🛑 Continuous sound stopped'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Stop sound failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.campaign,
              title: '🚨 Simulate FCM Auto Check-in',
              iconColor: Colors.red,
              onTap: () async {
                print('🚨 SIMULATING FCM AUTO CHECK-IN TRIGGER');
                print('🚨 This simulates exactly what FCM would send');
                try {
                  // Create the exact payload that FCM would send
                  final testData = {
                    'type': 'auto_checkin_trigger',
                    'task_id': 'test-task-${DateTime.now().millisecondsSinceEpoch}',
                    'task_name': 'Simulated Auto Check-in',
                    'start_time': '${DateTime.now().hour}:${DateTime.now().minute}',
                    'location': 'Simulated Location'
                  };
                  
                  print('🎯 FCM payload simulation: $testData');
                  print('🎯 This should trigger: notification + swiggy sound');
                  
                  // Call the same method that FCM would trigger
                  await NotificationService.showAutoCheckInNotification(
                    taskId: testData['task_id']!,
                    taskName: testData['task_name']!,
                    startTime: testData['start_time']!,
                    location: testData['location']!,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🚨 FCM simulation complete! Notification + Swiggy sound!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  print('❌ FCM simulation failed: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ FCM simulation failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            _buildListTile(
              context: context,
              icon: Icons.settings,
              title: "📱 Device Sound Settings Help",
              iconColor: Colors.orange,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('📱 Fix Notification Sound'),
                    content: const Text(
                      '1. Check iPhone volume (use volume buttons)\n\n'
                      '2. Silent Switch: Make sure switch on left side of phone is NOT orange\n\n'
                      '3. Go to Settings → Notifications → [Your App]\n'
                      '   • Allow Notifications = ON\n'
                      '   • Sounds = ON\n'
                      '   • Badge App Icon = ON\n\n'
                      '4. Go to Settings → Sounds & Haptics\n'
                      '   • Ringer and Alerts volume = UP\n\n'
                      '5. Make sure Do Not Disturb is OFF\n\n'
                      '6. Try restarting your iPhone'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it!'),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Cleared all offline actions
            // ElevatedButton(
            //   onPressed: () async {
            //     final db = await DBHelper().db;
            //     await db.delete('punch_actions');
                
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(content: Text('🧹 Cleared all offline actions')),
            //     );
            //   },
            //   child: const Text('Clear Offline Data (Testing Only)'),
            // ),

            const SizedBox(height: 12),

            // Logout Button
            GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                prefs.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      "Logout",
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

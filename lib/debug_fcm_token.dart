import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'notification_service.dart';

class FCMTokenDebugScreen extends StatefulWidget {
  const FCMTokenDebugScreen({Key? key}) : super(key: key);

  @override
  State<FCMTokenDebugScreen> createState() => _FCMTokenDebugScreenState();
}

class _FCMTokenDebugScreenState extends State<FCMTokenDebugScreen> {
  String? _fcmToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFCMToken();
  }

  Future<void> _loadFCMToken() async {
    setState(() => _isLoading = true);
    try {
      final token = await NotificationService.getToken();
      setState(() {
        _fcmToken = token;
        _isLoading = false;
      });
      print('🔑 Current FCM Token: $token');
    } catch (e) {
      setState(() {
        _fcmToken = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToken() async {
    if (_fcmToken != null && !_fcmToken!.startsWith('Error:')) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ FCM Token copied to clipboard!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Token Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '🔑 Current FCM Token',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: SelectableText(
                  _fcmToken ?? 'No token available',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _copyToken,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Token'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadFCMToken,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                print('🧪 Testing immediate local notification with sound...');
                await NotificationService.testNotificationWithSound();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔔 Local notification sent - check if sound played!')),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('🚨 IMMEDIATE TEST: Local Ring'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '📋 Instructions:\n'
              '1. Copy the current FCM token\n'
              '2. Replace the token in your FCM payload\n'
              '3. First test "Local Ring" to verify sound works\n'
              '4. Then send FCM notification with new token\n'
              '5. Watch console logs for detailed debugging',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
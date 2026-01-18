import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'notification_test.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({Key? key}) : super(key: key);

  @override
  _NotificationDebugScreenState createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  String _statusText = 'Tap buttons to test notifications';
  bool _isLoading = false;
  Map<String, dynamic>? _lastStatus;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Checking notification status...';
    });

    try {
      Map<String, dynamic> status = await NotificationService.getNotificationStatus();
      setState(() {
        _lastStatus = status;
        _statusText = 'Status checked - see details below';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Error checking status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testManualToken() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Generating token manually...';
    });

    try {
      String? token = await NotificationService.manualTokenGeneration();
      setState(() {
        _statusText = token != null 
          ? 'Manual token generated successfully!' 
          : 'Manual token generation failed';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Manual token error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Running full diagnostics...';
    });

    try {
      await NotificationTest.runDiagnostics();
      setState(() {
        _statusText = 'Diagnostics complete - check console for details';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Diagnostics error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getToken() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Getting FCM token...';
    });

    try {
      String? token = await NotificationService.getToken();
      setState(() {
        _statusText = token != null 
          ? 'Token: ${token.substring(0, 30)}...' 
          : 'No token available';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Token error: $e';
        _isLoading = false;
      });
    }
  }

  void _showTroubleshootingGuide() {
    NotificationTest.printTroubleshootingGuide();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Troubleshooting guide printed to console')),
    );
  }

  Future<void> _testAutoCheckInNotification() async {
    setState(() {
      _isLoading = true;
      _statusText = 'Testing auto check-in notification...';
    });

    try {
      await NotificationService.testAutoCheckInNotification();
      setState(() {
        _statusText = 'Auto check-in notification test triggered! Check if sound is playing.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Auto check-in test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _stopAutoCheckInSound() async {
    await NotificationService.stopContinuousSound();
    setState(() {
      _statusText = 'Auto check-in sound stopped';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_statusText),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_lastStatus != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detailed Status',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._lastStatus!.entries.map((entry) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key),
                              Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  color: entry.value == true ? Colors.green : 
                                         entry.value == false ? Colors.red : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _checkStatus,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Status'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _getToken,
                  icon: const Icon(Icons.token),
                  label: const Text('Get Token'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testManualToken,
                  icon: const Icon(Icons.build),
                  label: const Text('Manual Token'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runDiagnostics,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Run Diagnostics'),
                ),
                ElevatedButton.icon(
                  onPressed: _showTroubleshootingGuide,
                  icon: const Icon(Icons.help),
                  label: const Text('Help Guide'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Auto Check-in Test Section
            Card(
              color: Colors.deepPurple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚨 Auto Check-in Notification Test',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testAutoCheckInNotification,
                          icon: const Icon(Icons.alarm, color: Colors.orange),
                          label: const Text('Test Auto Check-in'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade100,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _stopAutoCheckInSound,
                          icon: const Icon(Icons.stop, color: Colors.red),
                          label: const Text('Stop Sound'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use this to test if the auto check-in notification with continuous music works correctly.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              color: Colors.orange,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'iOS Development Note',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'APNS token issues are normal in development mode. '
                      'Test on a physical device with proper certificates for production.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
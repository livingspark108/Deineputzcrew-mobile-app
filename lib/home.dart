import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:deineputzcrew/settings.dart';
import 'package:deineputzcrew/taskall.dart';
import 'package:deineputzcrew/taskdetails.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'db_helper.dart';
import 'main.dart';
import 'task_model.dart';
import 'location_service.dart';
import 'background_task_manager.dart';
import 'notification_service.dart';



class MainApp extends StatefulWidget {
  final int initialIndex;
  const MainApp({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // 👈 Start on passed index
    
    // Handle any notification when app is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAutoCheckInNotificationOnAppOpen();
    });
  }
  
  /// Handle any notification when app opens
  void _handleAutoCheckInNotificationOnAppOpen() async {
    // Check if any notification sound is playing
    if (NotificationService.isPlayingAutoCheckInSound) {
      final taskId = NotificationService.currentAutoCheckInTaskId;
      
      // Show dialog to acknowledge any notification
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text('🔔 Notification Alert'),
            ],
          ),
          content: Text(
            'You have an active notification.\n\n${taskId != null ? "Task ID: $taskId\n\n" : ""}Please acknowledge to continue.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Stop continuous sound
                await NotificationService.stopContinuousSound();
                Navigator.of(context).pop();
                
                // Check if user is logged in and reload home page
                await _reloadHomePageIfLoggedIn();
              },
              child: const Text('Acknowledge', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    }
  }
  
  /// Check if user is logged in and reload home page data
  Future<void> _reloadHomePageIfLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userid');
      
      // Check if user is logged in (has valid token and userId)
      if (token != null && token.isNotEmpty && userId != null && userId > 0) {
        print('🔄 User is logged in, reloading home page...');
        
        // Show loading indicator briefly
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔄 Refreshing data...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
        
        // Reload dashboard data if callback is available
        if (_reloadDashboard != null) {
          _reloadDashboard!();
          print('✅ Dashboard reload triggered');
        } else {
          // Fallback: Force rebuild of current page
          setState(() {});
          print('⚠️ Dashboard callback not available, forcing rebuild');
        }
        
        print('✅ Home page refreshed successfully');
      } else {
        print('❌ User not logged in, skipping home page reload');
      }
    } catch (e) {
      print('❌ Error reloading home page: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Failed to refresh: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Create pages dynamically to ensure fresh state on navigation
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(onReloadCallback: _reloadDashboard);
      case 1:
        return AllTasksScreen2();
      case 2:
        return SettingsScreen();
      default:
        return DashboardScreen(onReloadCallback: _reloadDashboard);
    }
  }
  
  // Global dashboard reload callback
  VoidCallback? _reloadDashboard;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),

        ],
      ),
    );
  }
}




class DashboardScreen extends StatefulWidget {
  final VoidCallback? onReloadCallback;

  //const DashboardScreen({super.key});
  DashboardScreen({super.key, this.onReloadCallback});

  StreamSubscription<ConnectivityResult>? _connectivitySub;


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();

}

bool isTaskTimeValid(Task task) {
    final now = DateTime.now();

    List<int> toHMS(String t) {
      final p = t.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      // ✅ SAFE ACCESS - handle missing parts
      return [
        p.isNotEmpty ? p[0] : 0,           // hours
        p.length > 1 ? p[1] : 0,           // minutes
        p.length > 2 ? p[2] : 0,           // seconds
      ];

      //return [p[0], p[1], p.length > 2 ? p[2] : 0];
    }

    final start = toHMS(task.startTime);
    final end = toHMS(task.endTime);

    DateTime startDt = DateTime(
      now.year, now.month, now.day,
      start[0], start[1], start[2],
    );

    DateTime endDt = DateTime(
      now.year, now.month, now.day,
      end[0], end[1], end[2],
    );

    // Overnight shift support
    if (endDt.isBefore(startDt)) {
      endDt = endDt.add(const Duration(days: 1));
    }

    return now.isAfter(startDt) && now.isBefore(endDt);
  }

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedPriority = "all"; // all | low | medium | high
  bool _isManualRefresh = false;
  Timer? _autoCheckoutTimer;
  bool _autoCheckoutLocked = false;
  bool _isSyncing = false;

  StreamSubscription<ConnectivityResult>? _connectivitySub;

  // ✅ Connectivity & Sync Status
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  Timer? _syncStatusTimer;
  
  // Location service for background monitoring
  final LocationService _locationService = LocationService();

  static  Duration _workingDuration = Duration.zero;
  static DateTime? _punchInTime;

  bool _isLoadingBreak = false;
  bool _isLoading = false; // Start with false, set true when needed
  String? _error; // Add error state
  //bool _initialized = false; // Add initialization flag
  String? punchedInTaskId;

  int userId = 0;
  String? token;
  List<dynamic> tasks = [];
  bool isClockedIn = false;
  bool isClockedOut = true;
  static Timer? _timer;
  bool isOnBreak = false;
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;

  static Duration _pausedDuration = Duration.zero;
  static bool _onBreak = false;

  void _startAutoCheckoutTimer() {
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAutoCheckout(),
    );
  }

  void _stopAutoCheckoutTimer() {
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = null;
  }


  Future<void> showAutoCheckoutNotification(String taskName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'auto_checkout_channel',
      'Auto Checkout',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();
    await notificationsPlugin.show(
      0,
      'Auto Checkout',
      'You were auto-checked out from "$taskName"',
      platformChannelSpecifics,
    );
  }
  Future<File> generateBlankImage() async {
    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/auto_checkout.jpg");

    // Minimal JPEG header
    await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]);
    return file;
  }

  @override
  void initState() {
    super.initState();
    print('🏠 DashboardScreen initState called');
    
    // Set up reload callback for parent widget
    if (widget.onReloadCallback != null) {
      // Pass our reload method to the parent
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.findAncestorStateOfType<_MainAppState>() != null) {
          context.findAncestorStateOfType<_MainAppState>()!._reloadDashboard = () async {
            print('🔄 Dashboard notification reload triggered (like swipe down)');
            
            // Use same logic as RefreshIndicator swipe-down
            _autoCheckoutLocked = true;      // 🔒 HARD LOCK
            _isManualRefresh = true;
            _stopAutoCheckoutTimer();

            await fetchTasks();
            await syncOfflineActions();

            _isManualRefresh = false;
            _autoCheckoutLocked = false;     // 🔓 UNLOCK
            _startAutoCheckoutTimer();
            
            print('✅ Dashboard notification reload completed');
          };
        }
      });
    }
    
    _initializeApp().then((_) {
      _startAutoCheckoutTimer();
      _startSyncStatusMonitoring();
    });

    _connectivitySub =
      Connectivity().onConnectivityChanged.listen((result) async {
      final isOnline = result != ConnectivityResult.none;
      setState(() {
        _isOnline = isOnline;
      });
      
      if (isOnline) {
        debugPrint("🌐 Internet restored → syncing offline data");
        await syncOfflineActions();
        await _updatePendingSyncCount();
        // 🔄 Reload dashboard after successful sync
        if (mounted) {
          await fetchTasks(); // reloads tasks & applies auto-hide logic
        }

      }
    });


    // Timer.periodic(const Duration(seconds: 30), (_) {
    //   _checkAutoCheckout();
    // });
    
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _syncStatusTimer?.cancel();
    _locationService.stopMonitoring();
    super.dispose();
  }


  // Future<void> _initializeApp() async {
  //   print('🚀 Starting app initialization...');
  //   try {
  //     await loadUserData();
  //     setState(() {
  //       _initialized = true;
  //     });
  //     print('✅ App initialization completed successfully');
  //   } catch (e) {
  //     print('❌ App initialization failed: $e');
  //     setState(() {
  //       _initialized = true;
  //       _error = 'Failed to initialize app: $e';
  //     });
  //   }
  // }
  Future<void> _initializeApp() async {
    if (!mounted) return;
  
    setState(() {
      _isLoading = true;
      //_initialized = false;
      _error = null;
    });

    _autoCheckoutLocked = true;
    try {
      // Check initial connectivity
      final connectivity = await Connectivity().checkConnectivity();
      setState(() {
        _isOnline = connectivity != ConnectivityResult.none;
      });

      await loadUserData(); // Loads tasks + restores timer state
      
      // ✅ Start location service with tasks
      await _locationService.startMonitoring(
        tasks: allTasks,
        onAutoCheckIn: _handleAutoCheckIn,
      );
      
      // ✅ FIXED: Sync AFTER timer state is restored
      await syncOfflineActions();
      await _updatePendingSyncCount();
      
      // 📱 Sync offline check-ins from BackgroundTaskManager
      await _syncBackgroundCheckIns();

      setState(() {
        //_initialized = true;
        _isLoading = false;
      });
      
      print('✅ App initialization completed successfully');
    } catch (e) {
      print('❌ App initialization failed: $e');
      setState(() {
        //_initialized = true;
        _isLoading = false;
        _error = 'Failed to initialize: $e';
      });
    } finally {
      _autoCheckoutLocked = false;
    }
  }

  /// Monitor sync status and connectivity
  void _startSyncStatusMonitoring() {
    _syncStatusTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updatePendingSyncCount(),
    );
  }

  /// Handle auto check-in callback from location service
  void _handleAutoCheckIn(String taskId, DateTime punchInTime) {
    debugPrint("📞 Auto check-in callback: $taskId at $punchInTime");
    
    if (mounted) {
      setState(() {
        selectedTaskId = taskId;
        _punchInTime = punchInTime;
      });
      
      // Start the dashboard timer
      startDashboardWorkTimer();
      
      // Update UI sync count
      _updatePendingSyncCount();
      
      // Show notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Auto Check-in completed (offline)'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Update pending sync count
  Future<void> _updatePendingSyncCount() async {
    try {
      final count = await DBHelper().getPendingSyncCount();
      if (mounted) {
        setState(() {
          _pendingSyncCount = count;
        });
      }
    } catch (e) {
      debugPrint("Error updating sync count: $e");
    }
  }

  Future<void> _checkAutoCheckout() async {
    if (_autoCheckoutLocked || _isManualRefresh) {
      debugPrint("⛔ Auto punch-out blocked (refresh/init)");
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final punchedTaskId = prefs.getString('punchedInTaskId');

    if (punchedTaskId == null || punchedTaskId.isEmpty) return;

    Task? task;
    try {
      task = allTasks.firstWhere((t) => t.id == punchedTaskId);
    } catch (_) {
      return;
    }

    // If completed, skip
    if (task.status.toLowerCase() == "completed") return;

    // TIME-BASED AUTO CHECKOUT
    if (_isTimeExceeded(task)) {
      await _autoPunchOut(task);
      return;
    }

    // LOCATION CHECK
    try {
      final pos = await Geolocator.getCurrentPosition();

      double distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        double.tryParse(task.lat) ?? 0.0,
        double.tryParse(task.longg) ?? 0.0,
      );

      // More than 300m away
      if (distance > 300) {
        await _autoPunchOut(task);
        return;
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // bool _isTimeExceeded(Task task) {
  //   final now = DateTime.now();

  //   List<int> hm(String s) {
  //     final p = s.split(':').map((e) => int.tryParse(e) ?? 0).toList();
  //     return [p[0], p[1], p.length > 2 ? p[2] : 0];
  //   }

  //   final endParts = hm(task.endTime);
  //   final endTime = DateTime(now.year, now.month, now.day,
  //       endParts[0], endParts[1], endParts[2]);

  //   // Handle overnight shifts
  //   if (endTime.isBefore(now)) {
  //     return true;
  //   }
  //   return false;
  // }
  bool _isTimeExceeded(Task task) {
    if (_punchInTime == null) return false;
    
    // Safety check: ensure endTime is not empty
    if (task.endTime.isEmpty || task.endTime.trim().isEmpty) {
      print('⚠️ Task ${task.id} has empty endTime - cannot check if time exceeded');
      return false;
    }

    final DateTime now = DateTime.now();

    List<int> hm(String s) {
      final p = s.split(':').map((e) => int.tryParse(e) ?? 0).toList();
      // Safety check: ensure we have at least hour and minute
      if (p.length < 2) {
        print('⚠️ Invalid time format: "$s" - expected HH:MM format');
        return [0, 0, 0]; // Return default values
      }
      return [p[0], p[1], p.length > 2 ? p[2] : 0];
    }

    final endParts = hm(task.endTime);
    
    // Additional safety check after parsing
    if (endParts.length < 2) {
      print('⚠️ Failed to parse endTime "${task.endTime}" for task ${task.id}');
      return false;
    }
    
    DateTime endTime = DateTime(
      _punchInTime!.year,
      _punchInTime!.month,
      _punchInTime!.day,
      endParts[0],
      endParts[1],
      endParts[2],
    );

    // overnight shift support
    if (endTime.isBefore(_punchInTime!)) {
      endTime = endTime.add(const Duration(days: 1));
    }

    return now.isAfter(endTime);
  }

  Future<void> _autoPunchOut(Task task) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final position = await Geolocator.getCurrentPosition();
    final blankImage = await generateBlankImage();

    //final now = DateTime.now().toIso8601String();
    final DateTime now = DateTime.now();

    final connectivity = await Connectivity().checkConnectivity();
    // OFFLINE → Save to SQLite
    if (connectivity == ConnectivityResult.none) {
      debugPrint("📴 Offline - Saving punch-out to DB");
      await DBHelper().insertPunchAction({
        'task_id': task.id,
        'type': 'punch-out',
        'lat': position.latitude.toStringAsFixed(6),
        'long': position.longitude.toStringAsFixed(6),
        'image_path': blankImage.path,
        'timestamp': now.toIso8601String(),
        'remark': 'Auto Punch-out',
        'synced': 0,
      });

      // ✅ ADD THIS DEBUG
      final saved = await DBHelper().getPunchActions();
      debugPrint("📊 Total offline actions after punch-out: ${saved.length}");
      for (var action in saved) {
        debugPrint("   - ${action['type']} at ${action['timestamp']}");
      }

      // Update UI
      await _updatePendingSyncCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📴 Auto Check-out saved offline. Will sync when online.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // ONLINE → Send to API
    var request = http.MultipartRequest(
      'POST',
      Uri.parse("https://admin.deineputzcrew.de/api/punch-out/"),
    );

    request.headers["Authorization"] = "token $token";
    request.fields["task_id"] = task.id;
    request.fields["lat"] = position.latitude.toStringAsFixed(6);
    request.fields["long"] = position.longitude.toStringAsFixed(6);
    request.fields["remark"] = "Auto Punch-out";

    request.files.add(await http.MultipartFile.fromPath(
      'images',
      blankImage.path,
      filename: "auto_checkout.jpg",
    ));

    final resp = await request.send();
    final body = await http.Response.fromStream(resp);

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      await _clearPunchPrefs();
      await showAutoCheckoutNotification(task.taskName);
    } else {
      // Save offline fallback

    }
  }

  Future<void> _clearPunchPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('punchedInTaskId');
    await prefs.remove('punchInStartTime');
    await prefs.remove('pausedDuration');
    await prefs.remove('breakDuration');
    await prefs.remove('onBreak');

    _timer?.cancel();
    _timer = null;

    _breakTimer?.cancel();
    _breakTimer = null;

    // ✔ Prevent setState after widget is disposed
    if (!mounted) return;

    setState(() {
      selectedTaskId = "";
      _onBreak = false;
      _workingDuration = Duration.zero;
      _pausedDuration = Duration.zero;
      _breakDuration = Duration.zero;
    });
  }


  // =========================
  // RESTORE TIMER STATE
  // =========================
  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();

    final storedTaskId = prefs.getString('punchedInTaskId');
    final startTimeStr = prefs.getString('punchInStartTime');
    final pausedDurationMillis = prefs.getInt('pausedDuration') ?? 0;
    final onBreak = prefs.getBool('onBreak') ?? false;
    // final breakDurationMillis = prefs.getInt('breakDuration') ?? 0;
    final breakStartStr = prefs.getString('breakStartTime');


    if (storedTaskId != null &&
        storedTaskId.isNotEmpty &&
        startTimeStr != null &&
        startTimeStr.isNotEmpty) {
      final startTime = DateTime.parse(startTimeStr);

      setState(() {
        selectedTaskId = storedTaskId;
        _punchInTime = startTime;
        _pausedDuration = Duration(milliseconds: pausedDurationMillis);
        _onBreak = onBreak;
        isClockedIn = true;
        isClockedOut = false;
      });

      if (_onBreak && breakStartStr != null) {
        _breakStartTime = DateTime.parse(breakStartStr);

        _breakTimer?.cancel();
        _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _breakDuration =
                DateTime.now().difference(_breakStartTime!);
          });
        });

        // Adjust working duration
        _workingDuration = DateTime.now().difference(_punchInTime!) -
            _pausedDuration -
            _breakDuration;
      } else {
        // ✅ Resume work timer
        _workingDuration =
            DateTime.now().difference(_punchInTime!) - _pausedDuration;

        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _workingDuration =
                DateTime.now().difference(_punchInTime!) - _pausedDuration;
            if (_workingDuration.isNegative) {
              _workingDuration = Duration.zero;
            }
          });
        });
      }
    } else {
      // Reset state if nothing found
      setState(() {
        selectedTaskId = "";
        _punchInTime = null;
        _workingDuration = Duration.zero;
        _pausedDuration = Duration.zero;
        _breakDuration = Duration.zero;
        _onBreak = false;
        isClockedIn = false;
        isClockedOut = true;
      });
    }
  }

// -------------------- START WORK TIMER --------------------
  void startDashboardWorkTimer({bool isResuming = false}) async {
    // ✅ FIXED: Prevent starting timer if already running
    if (_timer != null && _timer!.isActive) {
      debugPrint("⏸ Timer already running, skipping duplicate start");
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (!isResuming) {
      _punchInTime = DateTime.now();
      _pausedDuration = Duration.zero;
      await prefs.setString('punchInStartTime', _punchInTime!.toIso8601String());
      await prefs.setInt('pausedDuration', 0);
      await prefs.setBool('onBreak', false);
    }

    debugPrint("▶️ Starting work timer");
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_onBreak && _punchInTime != null) {
        setState(() {
          _workingDuration =
              DateTime.now().difference(_punchInTime!) - _pausedDuration;
          if (_workingDuration.isNegative) {
            _workingDuration = Duration.zero;
          }
        });
      }
    });


   }

// -------------------- PAUSE WORK (BREAK IN) --------------------
  void pauseDashboardWorkTimer() async {
    _timer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onBreak', true);

    // Start break timer fresh
    _breakDuration = Duration.zero;
    _breakStartTime = DateTime.now();

    // SAVE BREAK START TIME
    await prefs.setString(
      'breakStartTime',
      _breakStartTime!.toIso8601String(),
    );
    await prefs.setBool('onBreak', true);

    _breakTimer?.cancel();
    _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _breakDuration = DateTime.now().difference(_breakStartTime!);
      });
    });

    setState(() => _onBreak = true);
  }

// -------------------- RESUME WORK (BREAK OUT) --------------------
  void resumeDashboardWorkTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onBreak', false);

    if (_breakStartTime != null) {
      // ✅ Add break duration into paused duration
      final breakElapsed = DateTime.now().difference(_breakStartTime!);
      _pausedDuration += breakElapsed;
      _breakStartTime = null;
    }

    _breakTimer?.cancel();
    _breakDuration = Duration.zero;
    await prefs.setInt('breakDuration', 0);

    // Save updated paused duration
    await prefs.setInt('pausedDuration', _pausedDuration.inMilliseconds);

    setState(() => _onBreak = false);

    // Resume work timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_punchInTime != null) {
        setState(() {
          _workingDuration =
              DateTime.now().difference(_punchInTime!) - _pausedDuration;
          if (_workingDuration.isNegative) {
            _workingDuration = Duration.zero; // safety check
          }
        });
      }
    });
  }





  Future<void> loadUserData() async {
    print('📊 loadUserData called');
    // setState(() {
    //   _isLoading = true;
    //   _error = null;
    // });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userId = prefs.getInt('userid') ?? 0;
        token = prefs.getString('token');
      });
      
      // Call fetchTasks outside of setState
      await fetchTasks();

      //await syncOfflineActions();
      
      // setState(() {
      //   _isLoading = false;
      // });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load data: $e';
      });
    }
  }

  List<Task> taskList = [];
  List<Task> allTasks = [];
  Duration _breakDuration = Duration.zero;
  DateTime? _breakStartTime;
  Timer? _breakTimer;


  /* Future<void> fetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final response = await http.post(
      Uri.parse('https://admin.deineputzcrew.de/api/get_user_detail/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'token $token', // 🔑 add token here
      },
      body: jsonEncode({"id": userId}),
    );

    final data = jsonDecode(response.body);
    if (data['success']) {
      setState(() {
        allTasks = List<Task>.from(data['task'].map((t) => Task.fromJson(t)));
        taskList = List.from(allTasks);

        _restoreTimerState(); // Initialize visible list to all tasks
      });
    } else {
      // handle unauthorized or failed response

    }
  }*/

  Future<void> _checkAutoPunchIn() async {
    if (_isManualRefresh) {
      debugPrint("⏸ Auto punch-in skipped (manual refresh)");
      return;
    }
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    final prefs = await SharedPreferences.getInstance();
    String? alreadyPunchedTaskId = prefs.getString('punchedInTaskId');

    if (alreadyPunchedTaskId != null && alreadyPunchedTaskId.isNotEmpty) {
      print("⛔ Already punched into: $alreadyPunchedTaskId");
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();
    // if (connectivity == ConnectivityResult.none) {
    //   print("📴 Offline — auto punch-in disabled");
    //   return;
    // }
    //final now = DateTime.now();
    if (connectivity == ConnectivityResult.none) {
      // await DBHelper().insertPunchAction({
      //   'task_id': task.id,
      //   'type': 'punch-out',
      //   'lat': position.latitude.toStringAsFixed(6),
      //   'long': position.longitude.toStringAsFixed(6),
      //   'image_path': blankImage.path,
      //   'timestamp': now,
      //   'remark': 'Auto Punch-out',
      // });
      debugPrint("📴 Punch-out saved offline");
      return;
    }


    // CURRENT LOCATION
    Position pos;
    try {
      pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("❌ Cannot get location: $e");
      return;
    }

    final now = DateTime.now();
    final todayDate = DateFormat("yyyy-MM-dd").format(now);

    // TIME PARSER
    List<int> _toHMS(String time) {
      final parts = time.trim().split(':');
      return [
        int.tryParse(parts[0]) ?? 0,
        parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
        parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0
      ];
    }

    List<Map<String, dynamic>> matchedTasks = [];

    for (var t in allTasks) {
      print("Checking task: ${t.taskName}");

      // ❌ Skip completed
      if (t.status.toLowerCase() == "completed") continue;


      if (t.autoCheckin == false) continue;

      // 🔥 DATE CHECK (IMPORTANT)
      if (t.date != todayDate) {
        print("⛔ Date does not match today: ${t.date}");
        continue;
      }

      // TIME PARSING
      final start = _toHMS(t.startTime);
      final end = _toHMS(t.endTime);

      DateTime startDt = DateTime(now.year, now.month, now.day, start[0], start[1], start[2]);
      DateTime endDt = DateTime(now.year, now.month, now.day, end[0], end[1], end[2]);

      if (endDt.isBefore(startDt)) {
        endDt = endDt.add(const Duration(days: 1));
      }

      if (now.isBefore(startDt) || now.isAfter(endDt)) {
        print("⛔ Not in time window");
        continue;
      }

      double distance = Geolocator.distanceBetween(
        _toSixDecimals(pos.latitude),
        _toSixDecimals(pos.longitude),
        double.tryParse(t.lat) ?? 0.0,
        double.tryParse(t.longg) ?? 0.0,
      );


      if (distance > 500) {
        print("⛔ Too far (>1km)");
        continue;
      }

      matchedTasks.add({
        "task": t,
        "distance": distance,
        "startDt": startDt,
      });
    }

    if (matchedTasks.isEmpty) {
      print("ℹ No valid tasks for auto punch-in.");
      return;
    }

    // SORT NEAREST FIRST → THEN EARLIEST START
    matchedTasks.sort((a, b) {
      int d = (a["distance"] as double).compareTo(b["distance"] as double);
      if (d != 0) return d;
      return (a["startDt"] as DateTime).compareTo(b["startDt"] as DateTime);
    });

    Task bestTask = matchedTasks.first["task"];
    print("🔥 Auto Punching-In Task: ${bestTask.taskName}");

    await _autoPunchIn(bestTask);
  }

  Future<void> requestNotificationPermission() async {
    final androidImplementation = notificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> _autoPunchIn(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // Get current location
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Create a temporary empty image file
      final Directory tempDir = await getTemporaryDirectory();
      //final File emptyImage = File("assets/images/auto_check_in.jpeg");
      final File emptyImage = File("${tempDir.path}/auto_check_in.jpeg");

      // Write empty content (0 bytes) or minimal JPG header
      await emptyImage.writeAsBytes([0xFF, 0xD8, 0xFF, 0xD9]); // minimal valid JPG

      final DateTime now = DateTime.now();

      // ✅ CHECK CONNECTIVITY FIRST
      final connectivity = await Connectivity().checkConnectivity();
      
      // OFFLINE → Save to SQLite
      if (connectivity == ConnectivityResult.none) {
        debugPrint("📴 Offline - Saving auto punch-in to DB");
        await DBHelper().insertPunchAction({
          'task_id': task.id,
          'type': 'punch-in',
          'lat': _toSixDecimals(position.latitude).toString(),
          'long': _toSixDecimals(position.longitude).toString(),
          'image_path': emptyImage.path,
          'timestamp': now.toIso8601String(),
          'remark': 'Auto Punch-in',
          'synced': 0,
        });

        // Update local state
        await prefs.setString('punchedInTaskId', task.id);
        selectedTaskId = task.id;
        _punchInTime = now;

        startDashboardWorkTimer();

        // Update UI
        await _updatePendingSyncCount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📴 Auto Check-in saved offline. Will sync when online.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // ONLINE → Send to API
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://admin.deineputzcrew.de/api/punch-in/'),
      );

      request.headers['Authorization'] = 'token $token';

      request.fields['task_id'] = task.id;
      request.fields['lat'] = _toSixDecimals(position.latitude).toString();
      request.fields['long'] = _toSixDecimals(position.longitude).toString();

      // Attach blank file instead of camera image
      request.files.add(await http.MultipartFile.fromPath(
        'images',
        emptyImage.path,
        filename: "auto_punch_blank.jpg",
      ));

      final response = await request.send();
      final body = await http.Response.fromStream(response);

      print("📡 Auto Punch-In Response: ${body.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setString('punchedInTaskId', task.id);
        selectedTaskId = task.id;
        _punchInTime = now;

        startDashboardWorkTimer();

        // No snackbar needed (silent auto punch-in)
      }
    } catch (e) {
      print("❌ Auto punch-in failed: $e");
    }
  }
  double _toSixDecimals(double value) {
    // Convert to 3 decimals → then format to 6 decimals
    String three = value.toStringAsFixed(3);   // e.g. "26.892"
    String six = double.parse(three).toStringAsFixed(6); // "26.892000"
    return double.parse(six);
  }

  Future<void> fetchTasks() async {
    print('📡 fetchTasks called');
    if (!mounted) return;
    
    setState(() {
      _error = null;
    });
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      if (connectivityResult != ConnectivityResult.none) {
        // ✅ Online
        final response = await http.post(
          Uri.parse('https://admin.deineputzcrew.de/api/get_user_detail/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'token $token',
          },
          body: jsonEncode({"id": userId}),
        ).timeout(const Duration(seconds: 10));

        final data = jsonDecode(response.body);

        if (data['success']) {
          final List<dynamic> taskByDate = data['task_by_date'] ?? [];

          // 🔑 Flatten all tasks
          final List<Task> tasks = taskByDate.expand((dayData) {
            final String day = dayData['day'] ?? "";
            final String date = dayData['date'] ?? "";
            final List<dynamic> jsonTasks = dayData['tasks'] ?? [];

            return jsonTasks
                .where((t) => (t['status'] ?? '').toLowerCase() != 'completed')
                .map((t) => Task.fromJson(t, day: day, date: date));
          }).toList();

        // 🔥 SORT → LATEST FIRST (DATE + START TIME)
        tasks.sort((a, b) {
          DateTime parseDateTime(Task t) {
            try {
              final d = DateTime.parse(t.date!); // yyyy-MM-dd

              final parts = t.startTime.split(':');
              final h = int.tryParse(parts[0]) ?? 0;
              final m = int.tryParse(parts[1]) ?? 0;
              final s = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

              return DateTime(d.year, d.month, d.day, h, m, s);
            } catch (_) {
              return DateTime(1970);
            }
          }

          return parseDateTime(b).compareTo(parseDateTime(a));
        });

        final db = DBHelper();
        await db.clearTasks(); // clear old tasks

        for (final task in tasks) {
          await db.insertTask(task.toMap());
        }
        setState(() {
          allTasks = tasks;
          taskList = List.from(allTasks);
        });

        // ✅ Update location service with new tasks
        _locationService.updateTasks(tasks);

        _restoreTimerState();
        await _checkAutoPunchIn();
        } else {
          throw Exception('Failed to fetch tasks: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        // ❌ Offline → load from SQLite
        final offlineTasks = await DBHelper().getTasks();

        //final parsed = offlineTasks.map((t) => Task.fromJson(t)).toList();
        final parsed = offlineTasks.map((t) => Task.fromMap(t)).toList();


        // 🔥 SORT OFFLINE TASKS ALSO
        parsed.sort((a, b) {
          DateTime parseDateTime(Task t) {
            try {
              final d = DateTime.parse(t.date!);
              final parts = t.startTime.split(':');
              return DateTime(
                d.year,
                d.month,
                d.day,
                int.tryParse(parts[0]) ?? 0,
                int.tryParse(parts[1]) ?? 0,
              );
            } catch (_) {
              return DateTime(1970);
            }
          }

          return parseDateTime(b).compareTo(parseDateTime(a));
        });

        setState(() {
          allTasks = parsed;
          taskList = List.from(allTasks);
        });

        // 📱 Update BackgroundTaskManager with new tasks
        try {
          await BackgroundTaskManager.refreshTasks();
          print('✅ BackgroundTaskManager refreshed with new tasks');
        } catch (e) {
          print('⚠️ Failed to update BackgroundTaskManager: $e');
        }

        // ✅ Update location service with offline tasks
        _locationService.updateTasks(parsed);

        _restoreTimerState();
      }
    } catch (e) {
      // ✅ FIXED: Fallback to offline on any error
      debugPrint('❌ Online fetch failed: $e, loading offline...');
      
      try {
        final offlineTasks = await DBHelper().getTasks();
        final parsed = offlineTasks.map((t) => Task.fromMap(t)).toList();

        parsed.sort((a, b) {
          DateTime parseDateTime(Task t) {
            try {
              final d = DateTime.parse(t.date!);
              final parts = t.startTime.split(':');
              return DateTime(
                d.year, d.month, d.day,
                int.tryParse(parts[0]) ?? 0,
                int.tryParse(parts[1]) ?? 0,
              );
            } catch (_) {
              return DateTime(1970);
            }
          }
          return parseDateTime(b).compareTo(parseDateTime(a));
        });

        setState(() {
          allTasks = parsed;
          taskList = List.from(allTasks);
          _error = 'Offline mode: Showing cached tasks';
        });

        // 📱 Update BackgroundTaskManager with cached tasks
        try {
          await BackgroundTaskManager.refreshTasks();
          print('✅ BackgroundTaskManager refreshed with cached tasks');
        } catch (e) {
          print('⚠️ Failed to update BackgroundTaskManager with cached tasks: $e');
        }

        // ✅ Update location service with cached tasks
        _locationService.updateTasks(parsed);

        _restoreTimerState();
      } catch (offlineError) {
        debugPrint('❌ Offline load also failed: $offlineError');
        if (mounted) {
          setState(() {
            _error = 'Cannot load tasks';
            allTasks = [];
            taskList = [];
          });
        }
      }
    }
  }




  Future<void> syncOfflineActions() async {
    if (_isSyncing) {
      debugPrint("⏸ Sync already in progress, skipping...");
      return;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("📴 No internet, skipping sync");
      return;
    }

    // ✅ FLAG
    _isSyncing = true;

    try {

      final pendingData = await DBHelper().getPunchActions();

      // ✅ ADD THIS DEBUG BLOCK
      debugPrint("📊 Database check BEFORE sync:");
      debugPrint("   Total actions to sync: ${pendingData.length}");
      for (var action in pendingData) {
        debugPrint("   - ID: ${action['id']}, Type: ${action['type']}, Time: ${action['timestamp']}");
      }
      // END DEBUG

      if (pendingData.isEmpty) {
        debugPrint("No offline actions to sync");
        return;
      }

      // ✅ FIXED: Create a mutable copy before sorting
      final pending = List<Map<String, dynamic>>.from(pendingData);

      // ✅ Sort by timestamp to maintain order
      pending.sort((a, b) {
        final timeA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(1970);
        final timeB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(1970);
        return timeA.compareTo(timeB);
      });

      debugPrint("📤 Syncing ${pending.length} offline actions...");

      // ✅ ADD THIS: Show progress to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📤 Syncing ${pending.length} offline actions...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      int syncedCount = 0;

      for (var action in pending) {
        try {
          final type = action['type']; // punch-in / punch-out / break_in / break_out
          String endpoint = "";

          // Map DB type to API endpoint
          switch (type) {
            case "punch-in":
              endpoint = "punch-in";
              break;
            case "punch-out":
              endpoint = "punch-out";
              break;
            case "break_in":
              endpoint = "break-in";
              break;
            case "break_out":
              endpoint = "break-out";
              break;
            default:
              debugPrint("⚠️ Unknown action type: $type");
              continue;
          }

          final uri = Uri.parse("https://admin.deineputzcrew.de/api/$endpoint/");
          var request = http.MultipartRequest("POST", uri);

          final prefs = await SharedPreferences.getInstance();
          String? token = prefs.getString("token");
          if (token != null) {
            request.headers["Authorization"] = "token $token";
          }

          // Common fields
          request.fields["task_id"] = action["task_id"] ?? "";
          request.fields["lat"] = action["lat"] ?? "";
          request.fields["long"] = action["long"] ?? "";
          request.fields["timestamp"] = action["timestamp"] ?? "";
          
          // ✅ DEBUG: Log the exact timestamp being sent
          debugPrint("📡 Sending timestamp to API: ${action["timestamp"]} (Original location time)");

          // Optional: remark for punch-out
          if (action.containsKey("remark") && action["remark"] != null) {
            request.fields["remark"] = action["remark"];
          }

          // ✅ FIXED: Check if image file exists before attaching
          if (action["image_path"] != null && 
              action["image_path"].toString().isNotEmpty) {
            final imageFile = File(action["image_path"]);
            
            if (await imageFile.exists()) {
              request.files.add(await http.MultipartFile.fromPath(
                "images",
                action["image_path"],
                filename: path.basename(action["image_path"]),
              ));
            } else {
              debugPrint("⚠️ Image not found: ${action["image_path"]}");
              // Continue without image (backend should handle optional images)
            }
          }

          // Send to API
          final response = await request.send();
          final resBody = await http.Response.fromStream(response);
          debugPrint("📡 Sync response ($type): ${resBody.statusCode} ${resBody.body}");

          if (response.statusCode == 200 || response.statusCode == 201) {
            await DBHelper().deletePunchAction(action["id"]);
            syncedCount++;
            debugPrint("✅ Synced action ${action['id']}");
          }
          else if (response.statusCode == 400) {
            try {
              final errorBody = jsonDecode(resBody.body);
              final errorMsg = errorBody['error']?.toString().toLowerCase() ?? '';
              
              // ✅ Expanded list of permanent errors that should delete the action
              if (errorMsg.contains('already completed') ||
                  errorMsg.contains('duplicate') ||
                  errorMsg.contains('invalid task') ||
                  errorMsg.contains('task not found') ||
                  errorMsg.contains('after the task end time') ||          // ✅ NEW
                  errorMsg.contains('before the task start time') ||       // ✅ NEW
                  errorMsg.contains('task has ended') ||                   // ✅ NEW
                  errorMsg.contains('already punched in') ||               // ✅ NEW
                  errorMsg.contains('already punched out') || 
                  errorMsg.contains('not punched in') ||                   // ✅ NEW
                  errorMsg.contains('already on break') ||                 // ✅ NEW
                  errorMsg.contains('not on break')) {                     // ✅ NEW
                await DBHelper().deletePunchAction(action["id"]);
                debugPrint("🗑 Deleted stale action: $errorMsg");
              } else {
                debugPrint("⏳ Temporary error, will retry: $errorMsg");
              }
            } catch (e) {
              debugPrint("⏳ Cannot parse error, will retry later");
            }
          }
          else {
            debugPrint("⏳ Will retry later");
          }

        } catch (e) {
          debugPrint("❌ Sync error: $e");
        }
      }

      // ✅ ADD THIS: Show completion
      if (mounted && syncedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Synced $syncedCount actions successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Update UI with new pending count
      await _updatePendingSyncCount();
    } finally {
      // 🔓 ALWAYS UNLOCK
      _isSyncing = false;
      debugPrint("🔓 Sync lock released");
    }
  }

  /// Sync offline check-ins from BackgroundTaskManager
  Future<void> _syncBackgroundCheckIns() async {
    try {
      print('🔄 Syncing background check-ins...');
      await BackgroundTaskManager.syncOfflineCheckIns();
      print('✅ Background check-ins synced successfully');
    } catch (e) {
      print('⚠️ Failed to sync background check-ins: $e');
    }
  }


  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }



  /*Future<bool> callBreakInApi(String taskId, BuildContext context) async {
    try {
      final position = await _getCurrentLocation();
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication error. Please log in again.")),
        );
        return false;
      }

      final uri = Uri.parse('https://admin.deineputzcrew.de/api/break-in/');
      final response = await http.post(
        Uri.parse('https://admin.deineputzcrew.de/api/break-in/'),
        headers: {
          'Authorization': 'token $token',  // must be lowercase 'token'
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "task_id": taskId,                // should be a string UUID
          "lat": position.latitude.toStringAsFixed(4),         // number
          "long": position.longitude.toStringAsFixed(4),       // number
        }),
      );
print(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setBool('onBreak', true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Break In Successful.")),
        );

        return true;
      } else {
        await prefs.setBool('onBreak', true);
        print('Break-in failed: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Break In failed (${response.statusCode}).")),
        );
        return true;
      }
    } catch (e) {
      print("Break-in error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Break In error: $e")),
      );
      return false;
    }
  }*/
  /*Future<bool> callBreakOutApi(String taskId,BuildContext context) async {
    try {
      final position = await _getCurrentLocation();
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication error. Please log in again.")),
        );
        return false;
      }

      final uri = Uri.parse('https://admin.deineputzcrew.de/api/break-out/');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "task_id": taskId,
          "lat": position.latitude.toStringAsFixed(6),
          "long": position.longitude.toStringAsFixed(6),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setBool('onBreak', false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Break In Successful.")),
        );

        return true;
      } else {
        print('Break-out failed: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Break In failed (${response.statusCode}).")),
        );
        return false;
      }
    } catch (e) {
      print("Break-in error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Break In error: $e")),
      );
      return false;
    }// Or false if failed
  }*/
  Future<bool> callBreakInApi(String taskId, BuildContext context) async {
    try {
      final position = await _getCurrentLocation();
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final connectivity = await Connectivity().checkConnectivity();

      // ================= OFFLINE =================
      if (connectivity == ConnectivityResult.none) {
        await DBHelper().insertPunchAction({
          'task_id': taskId,
          'type': 'break_in',
          'lat': position.latitude.toStringAsFixed(6),
          'long': position.longitude.toStringAsFixed(6),
          'image_path': '',
          'timestamp': DateTime.now().toIso8601String(),
          'remark': 'Break In (Offline)',
          'synced': 0,
        });

        await prefs.setBool('onBreak', true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⏸ Break-In saved offline")),
        );

        return true;
      }

      // ================= ONLINE =================
      final response = await http.post(
        Uri.parse('https://admin.deineputzcrew.de/api/break-in/'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "task_id": taskId,
          "lat": position.latitude.toStringAsFixed(6),
          "long": position.longitude.toStringAsFixed(6),
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setBool('onBreak', true);
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Break-In failed (${response.statusCode})")),
      );
      return false;
    } catch (e) {
      debugPrint("Break-in error: $e");
      return false;
    }
  }

  Future<bool> callBreakOutApi(String taskId, BuildContext context) async {
    try {
      final position = await _getCurrentLocation();
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication error. Please log in again.")),
        );
        return false;
      }

      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        // ✅ FIXED: Now saving offline
        await DBHelper().insertPunchAction({
          'task_id': taskId,
          'type': 'break_out',
          'lat': position.latitude.toStringAsFixed(6),
          'long': position.longitude.toStringAsFixed(6),
          'image_path': '',
          'timestamp': DateTime.now().toIso8601String(),
          'remark': 'Break Out (Offline)',
          'synced': 0,
        });

        await prefs.setBool('onBreak', false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("▶️ Break-Out saved offline. Will sync later.")),
        );
        return true;
      }

      // ✅ Online → Call API
      final response = await http.post(
        Uri.parse('https://admin.deineputzcrew.de/api/break-out/'),
        headers: {
          'Authorization': 'token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "task_id": taskId,
          "lat": position.latitude.toStringAsFixed(6),
          "long": position.longitude.toStringAsFixed(6),
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setBool('onBreak', false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Break-Out successful.")),
        );
        return true;
      } else {
        print('Break-out failed: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Break-Out failed (${response.statusCode}).")),
        );
        return false;
      }
    } catch (e) {
      print("Break-out error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
      return false;
    }
  }
  Widget _priorityChip(String label) {
    final bool isSelected =
        selectedPriority == label.toLowerCase();

    Color chipColor;
    switch (label.toLowerCase()) {
      case "high":
        chipColor = Colors.red;
        break;
      case "medium":
        chipColor = Colors.orange;
        break;
      case "low":
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.black;
    }

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      onSelected: (_) {
        setState(() {
          selectedPriority = label.toLowerCase();
          _applyDashboardFilters();
        });
      },
    );
  }
  void _applyDashboardFilters() {
    List<Task> filtered = allTasks;

    // 🔹 Priority filter
    if (selectedPriority != "all") {
      filtered = filtered
          .where((t) =>
      t.priority.toLowerCase() == selectedPriority)
          .toList();
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered
          .where((t) =>
          t.taskName.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      taskList = filtered;
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _workingDuration = Duration.zero;
  }
  Widget buildTimerCard(BuildContext context, String date) {
    // Get selected task safely from allTasks
    final Duration currentDuration = _onBreak ? _breakDuration : _workingDuration;

    final Task selectedTask = allTasks.firstWhere(
          (task) => task.id == selectedTaskId,
      orElse: () => Task(
        id: 'N/A',
        taskName: 'No Task Selected',
        startTime: '',
        endTime: '',
        autoCheckin: false,
        locationName: '',
        priority: '',
        status: '',
          lat: '',
          longg: '',
        punchIn: false,
        punchOut: false,
        breakIn: false,
        breakOut: false,
        day: "",
        date:"",
        totalWorkTime: "0h 0m",
      ),
    );

    // Reset timer if no task selected
    if (selectedTask.id == 'N/A') {
      setState(() {
        _timer?.cancel();
        _workingDuration = Duration.zero;
        _pausedDuration = Duration.zero;   // also reset paused duration
        _breakDuration = Duration.zero;    // also reset break duration
        _onBreak = false;
      });
    }


    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 18 to 12
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Reduced from 16 to 10

          // Timer Row - Only show when task is selected and timer running
          if (selectedTaskId.isNotEmpty && (currentDuration.inSeconds > 0 || _timer != null))
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TimerDigit(
                  value: currentDuration.inHours.toString().padLeft(2, '0'),
                  label: 'Hrs',
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                _TimerDigit(
                  value: (currentDuration.inMinutes % 60).toString().padLeft(2, '0'),
                  label: 'Mins',
                  color: Colors.purple,
                ),
                const SizedBox(width: 6),
                _TimerDigit(
                  value: (currentDuration.inSeconds % 60).toString().padLeft(2, '0'),
                  label: 'Secs',
                  color: Colors.pink,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Task info - Only show when task is selected
          if (selectedTaskId.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                selectedTask.taskName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: selectedTaskId.isNotEmpty 
                  ? Text(
                      selectedTask.locationName.isNotEmpty
                          ? selectedTask.locationName
                          : '',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    )
                  : null, // Hide subtitle when no task selected
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          const SizedBox(height: 12),

          // Clock In / Clock Out Buttons




          // Break + Clock Out Row - Only show when task is selected
          if (selectedTaskId.isNotEmpty) 
            Row(
              children: [
                // Break button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (selectedTaskId == null || selectedTaskId!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a task before starting a break.'),
                          ),
                        );
                        return;
                      }

                      setState(() => _isLoadingBreak = true);
                      final prefs = await SharedPreferences.getInstance();

                      if (_onBreak) {
                        // ✅ Break OUT
                        bool success = await callBreakOutApi(selectedTaskId!, context);
                        if (success) {
                          resumeDashboardWorkTimer();
                        }
                      } else {
                        // ✅ Break IN
                        bool success = await callBreakInApi(selectedTaskId!, context);
                        if (success) {
                          pauseDashboardWorkTimer();
                          await prefs.setBool('onBreak', true);
                        }
                      }

                      setState(() => _isLoadingBreak = false);
                    },
                    icon: _isLoadingBreak
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Icon(
                      Icons.free_breakfast,
                      color: _onBreak ? Colors.green : Colors.orange,
                    ),
                    label: Text(
                      _onBreak ? 'End Break' : 'Go for Break',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: _onBreak ? Colors.green : Colors.orange,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _onBreak ? Colors.green : Colors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),


                const SizedBox(width: 12),

                // Clock Out button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Task? punchedInTask;
                      try {
                        punchedInTask =
                            allTasks.firstWhere((task) => task.id == selectedTaskId);
                      } catch (e) {
                        punchedInTask = null;
                      }

                      if (punchedInTask != null) {
                        final totalDuration = _workingDuration; // Already contains accumulated work time

                        final bool? punchedOut = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TaskDetailsScreen(
                              title: punchedInTask!.taskName,
                              time: punchedInTask.timeRange,
                              location: punchedInTask.locationName,
                              duration: formatDuration(totalDuration), // pass total work duration
                              highPriority: punchedInTask.priority,
                              completed: punchedInTask.status,
                              taskId: punchedInTask.id,
                            ),
                          ),
                        );

                        if (punchedOut == true) {
                          stopTimer(); // stops both work and break timers
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No punched-in task found.")),
                        );
                      }

                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Clock Out',
                      style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    print('🖼️ DashboardScreen build called - _isLoading: $_isLoading, _initialized:  _error: $_error');
    
    // Always return a Scaffold to prevent white screen
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _buildMainContent(),
      ),
    );
  }
  
  Widget _buildMainContent() {
    // Show error state first
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Error: $_error', textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeApp(),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // // Show loading state
    // if (!_initialized || _isLoading) {
    //   return Center(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         CircularProgressIndicator(),
    //         SizedBox(height: 16),
    //         Text(_initialized ? 'Loading tasks...' : 'Initializing...'),
    //       ],
    //     ),
    //   );
    // }
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard...'),
          ],
        ),
      );
    }

    
    // Show main dashboard content
    final now = DateTime.now();
    final date = DateFormat('MMMM d, EEEE').format(now);

    return RefreshIndicator(
      //onRefresh: fetchTasks,
      onRefresh: () async {
        _autoCheckoutLocked = true;      // 🔒 HARD LOCK
        _isManualRefresh = true;
        _stopAutoCheckoutTimer();

        await fetchTasks();
        await syncOfflineActions();


        _isManualRefresh = false;
        _autoCheckoutLocked = false;     // 🔓 UNLOCK
        _startAutoCheckoutTimer();
      },


      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Connectivity & Sync Status Banner
            if (!_isOnline || _pendingSyncCount > 0) _buildStatusBanner(),
            if (!_isOnline || _pendingSyncCount > 0) const SizedBox(height: 12),

            const Text(
              '',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 14),
            _buildSearchBar(),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              children: [
                _priorityChip("All"),
                _priorityChip("Low"),
                _priorityChip("Medium"),
                _priorityChip("High"),
              ],
            ),
            const SizedBox(height: 10),

            buildTimerCard(context, date),
            const SizedBox(height: 16),
            _buildTaskHeader(context),
            const SizedBox(height: 10),
            _buildTaskList(),
          ],
        ),
      ),
    );
  }

  final TextEditingController _searchController = TextEditingController();

  void _filterTasks(String query) {
    final filtered = allTasks.where((task) {
      final taskNameLower = task.taskName.toLowerCase();
      final queryLower = query.toLowerCase();
      return taskNameLower.contains(queryLower);
    }).toList();

    setState(() {
      taskList = filtered;
    });
  }

  String formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _filterTasks,
      decoration: InputDecoration(
        hintText: 'Search tasks...',
        prefixIcon: const Icon(Icons.search),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Status banner showing offline/sync status
  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: !_isOnline ? Colors.orange.shade100 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: !_isOnline ? Colors.orange.shade300 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            !_isOnline ? Icons.cloud_off : Icons.sync,
            color: !_isOnline ? Colors.orange.shade700 : Colors.blue.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !_isOnline ? '📴 Offline Mode' : '📤 Syncing Data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: !_isOnline ? Colors.orange.shade900 : Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  !_isOnline
                      ? 'Check-ins/outs will be saved and synced when online'
                      : '$_pendingSyncCount action${_pendingSyncCount == 1 ? '' : 's'} pending sync',
                  style: TextStyle(
                    fontSize: 12,
                    color: !_isOnline ? Colors.orange.shade700 : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (_pendingSyncCount > 0 && _isOnline)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue.shade700),
              onPressed: () async {
                await syncOfflineActions();
                await _updatePendingSyncCount();
              },
              tooltip: 'Sync now',
            ),
        ],
      ),
    );
  }


  Widget _buildTaskHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Today\'s Tasks',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Poppins')),
        TextButton(
          onPressed: () {

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AllTasksScreen2()),
            );

          },
          child: const Text('View all',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.blue)),
        )
      ],
    );
  }
  String selectedTaskId = '';


  Widget _buildTaskList() {
    if (taskList.isEmpty) {
      return const Center(
        child: Text(
            "No tasks available", style: TextStyle(fontFamily: 'Poppins')),
      );
    }




    return


      ListView.builder(
        shrinkWrap: true,
        itemCount: taskList.length,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final task = taskList[index];
          return TaskCard(
            title: task.taskName,
            time: task.timeRange,
            location: task.locationName,
            duration: task.totalWorkTime,
            highPriority: task.priority,
            completed: task.status,
            taskId: task.id,


            punchIn: task.punchIn,
            selectedTaskId: selectedTaskId ?? "",
            punchedInTaskId: punchedInTaskId ?? "",
            taskList: taskList,
            day: task.day,
            date: task.date,
              lat:task.lat,
            longg: task.longg,// ✅ add this
            onTaskSelected: (id) {
              final taskObj = taskList.firstWhere((t) => t.id == id);
              setState(() {

                if(selectedTaskId ==""){
                  startDashboardWorkTimer();
                }
                selectedTaskId = id;

              });
            },
            onPunchIn: () async {
              setState(() {
                selectedTaskId = task.id;
              });
              startDashboardWorkTimer();
            },
            onPunchStart: () {},
          );

        },
      );
  }
}




// Simple placeholder screens for navigation



// Reusable Widgets
class _TimerDigit extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _TimerDigit(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: color,
                fontFamily: 'Poppins')),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: Colors.black54, fontFamily: 'Poppins')),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String subtitle;
  const _InfoBox({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins')),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontFamily: 'Poppins')),
      ],
    );
  }
}



class TaskCard extends StatefulWidget {

  final String taskId;
  final String title;
  final String time;
  final String location;
  final String duration;
  final String highPriority;
  final String completed;
  final bool punchIn;
  String selectedTaskId;
  String punchedInTaskId;
  final Function(String) onTaskSelected;
  final VoidCallback onPunchIn;
  final VoidCallback onPunchStart;
  final List<Task> taskList;
  final String? day;
  final String? date;
  final String? lat;
  final String? longg;
  TaskCard({
    super.key,
    required this.taskId,
    required this.title,
    required this.time,
    required this.location,
    required this.duration,
    required this.highPriority,
    required this.completed,
    required this.punchIn,
    required this.selectedTaskId,
    required this.punchedInTaskId,
    required this.onTaskSelected,

    required this.onPunchIn,
    required this.onPunchStart,
    required this.taskList,
    this.day,
    this.date,
    required this.lat,
    required this.longg,

  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool isSelected = false;
  

  // Add this method to _TaskCardState class
  Future<bool> _hasOfflinePunchOut(String taskId) async {
    final actions = await DBHelper().db.then((db) => 
      db.query(
        'punch_actions',
        where: 'task_id = ? AND type = ?',
        whereArgs: [taskId, 'punch-out'],
      )
    );
    return actions.isNotEmpty;
  } 

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
/* Future<void> _handlePunchIn(BuildContext context) async {
    try {
      widget.onPunchStart();

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Take photo
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        Navigator.pop(context);
        return;
      }

      // Get location
      final position = await _getCurrentLocation();

      // Check internet
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        // ❌ Offline → Save in SQLite
        await DBHelper().insertPunchAction({
          'task_id': widget.taskId,
          'type': 'punch-in',
          'lat': position.latitude.toStringAsFixed(4),
          'long': position.longitude.toStringAsFixed(4),
          'image_path': image.path,
          'timestamp': DateTime.now().toIso8601String(),
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Punch saved offline. Will sync later.')),
        );

         widget.onPunchIn();
        setState(() {
          widget.punchedInTaskId = widget.taskId;
          widget.onTaskSelected(widget.taskId);
        });

        setState(() {
          isSelected = true;
        });
        return;
      }

      // ✅ Online → Send API directly
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://admin.deineputzcrew.de/api/punch-in/'),
      );

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      request.headers['Authorization'] = 'token $token';
      request.fields['task_id'] = widget.taskId;
      request.fields['lat'] = position.latitude.toStringAsFixed(4);
      request.fields['long'] = position.longitude.toStringAsFixed(4);

      request.files.add(await http.MultipartFile.fromPath(
        'images',
        image.path,
        filename: path.basename(image.path),
      ));

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);


      final Map<String, dynamic> responseData = jsonDecode(responseBody.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Punch-in successful')),
        );
        widget.onPunchIn();
      } else {
        throw Exception("Server error: ${responseBody.body}");
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }*/

  Future<void> _handlePunchIn(BuildContext context) async {
    try {
      // ✅ CHECK IF ALREADY PUNCHED OUT OFFLINE
      final hasPunchOut = await _hasOfflinePunchOut(widget.taskId);
      if (hasPunchOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⛔ You already punched out from this task (offline). Cannot punch in again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      widget.onPunchStart();

      // Show loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Take photo
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) {
        Navigator.pop(context);
        return;
      }

      // Get location
      final position = await _getCurrentLocation();

      // Check internet FIRST
      final connectivity = await Connectivity().checkConnectivity();


      // 🔒 BLOCK INVALID OFFLINE PUNCH
      if (!isTaskTimeValid(widget.taskList.firstWhere(
            (t) => t.id == widget.taskId,
      ))) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "⛔ Punch-in/out isn't available for this task right now.",
            ),
          ),
        );
        return;
      }


      // ==========================
      // 🔴 OFFLINE MODE
      // ==========================
      if (connectivity == ConnectivityResult.none) {
        await DBHelper().insertPunchAction({
          'task_id': widget.taskId,
          'type': 'punch-in',
          'lat': position.latitude.toStringAsFixed(6),
          'long': position.longitude.toStringAsFixed(6),
          'image_path': image.path,
          'timestamp': DateTime.now().toIso8601String(),
          'remark': 'Offline Punch-In',
          'synced': 0,
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('punchedInTaskId', widget.taskId);

        Navigator.pop(context); // close loader

        // UI updates
        widget.onPunchIn();
        widget.onTaskSelected(widget.taskId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📴 Punch-in saved offline. Will sync automatically.'),
          ),
        );

        return; // ⛔ STOP HERE (NO API CALL)
      }

      // ==========================
      // 🟢 ONLINE MODE
      // ==========================
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://admin.deineputzcrew.de/api/punch-in/'),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      request.headers['Authorization'] = 'token $token';
      request.fields['task_id'] = widget.taskId;
      request.fields['lat'] = position.latitude.toStringAsFixed(6);
      request.fields['long'] = position.longitude.toStringAsFixed(6);

      request.files.add(await http.MultipartFile.fromPath(
        'images',
        image.path,
      ));

      final response = await request.send();
      final body = await http.Response.fromStream(response);

      Navigator.pop(context); // close loader

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setString('punchedInTaskId', widget.taskId);

        debugPrint("✅ Punch-in API success, calling onPunchIn()");
        widget.onPunchIn();

        debugPrint("📌 Selecting task: ${widget.taskId}");
        widget.onTaskSelected(widget.taskId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Punch-in successful')),
        );
      } else {
        throw Exception(body.body);
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Punch-in failed: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  
  Future<void> _openMap(double latitude, double longitude) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }



  @override
  Widget build(BuildContext context) {
    final bool isHigh = widget.highPriority.toLowerCase() == "high";
    final bool isCompleted =widget. completed.toLowerCase() == "completed";
    final bool isSelected = widget.selectedTaskId == widget.taskId;

    return
      InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        String storedPunchedInTaskId = prefs.getString('punchedInTaskId') ?? "";

        final bool isCompleted = widget.completed.toLowerCase() == "completed";
        final bool isCurrentPunchedIn = widget.taskId == storedPunchedInTaskId;

        // ✅ CHECK IF ALREADY PUNCHED OUT OFFLINE
        final hasPunchOut = await _hasOfflinePunchOut(widget.taskId);
        if (hasPunchOut && !isCurrentPunchedIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⛔ This task already has an offline punch-out. Cannot punch in again.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // ✅ If task is completed
        if (isCompleted) {
          // If this completed task is the one currently punched in, reset storedPunchedInTaskId
          if (isCurrentPunchedIn) {
            await prefs.remove('punchedInTaskId');
            storedPunchedInTaskId = "";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This task is already completed.')),
          );
          return;
        }
        else{

         /* if (!isCurrentPunchedIn) {
            await prefs.remove('punchedInTaskId');
            storedPunchedInTaskId = "";
          }*/

        }
        // ✅ If no task is punched in → punch this one in
        if (storedPunchedInTaskId.isEmpty) {
          await _handlePunchIn(context); // your punch-in function

          return;
        }

        // ✅ If a task is punched in, only allow tap if it's the same task
        if (isCurrentPunchedIn) {
          widget.onTaskSelected(widget.taskId);
        } else {
          // Get the currently punched-in task name
          final Task? punchedInTask = widget.taskList.firstWhere(
                (task) => task.id == storedPunchedInTaskId,

          );

          final String taskName = punchedInTask?.taskName ?? 'another task';


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are already punched into "$taskName".'),
            ),
          );
        }
      },






      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isHigh
              ? LinearGradient(
            colors: [Colors.orange.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isHigh
              ? null
              : (widget.punchedInTaskId.isNotEmpty &&
              widget.taskId != widget.punchedInTaskId &&
              widget.completed.toLowerCase() != "completed")
              ? Colors.grey.shade200
              : Colors.white,

          // <-- here
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? Border.all(color: Colors.blueAccent, width: 1.5)
              : null,
        ),        child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: isCompleted ? Colors.green : Colors.grey.shade400,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${widget.day} • ${widget.date}", style: TextStyle(fontSize: 12, color: Colors.grey)),

                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHigh)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'High',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    if (widget.punchIn && widget.completed!='completed')
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Punched In',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _openMap(
                    double.parse(widget.lat!) ,
                    double.parse(widget.longg!) ,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.location, // still show location name/address
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            decoration: TextDecoration.underline, // looks clickable
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.schedule,
                        size: 14, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      widget.time,
                      style: const TextStyle(
                          fontSize: 13, fontFamily: 'Poppins'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

              ],
            ),
          ),


          Row(
            children: [
              const Icon(Icons.access_time,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 4),
              Text(
                widget. duration,
                style:
                const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
              ),
            ],
          )
        ],
      ),
      ),
    );
  }
}



class PunchResponse {
  final String? error;
  final int? id;
  final List<String> images;
  final String? punchType;
  final String? timestamp;
  final String? lat;
  final String? long;
  final bool? onLocation;
  final int? user;
  final String? task;

  PunchResponse({
    this.error,
    this.id,
    this.images = const [],
    this.punchType,
    this.timestamp,
    this.lat,
    this.long,
    this.onLocation,
    this.user,
    this.task,
  });

  factory PunchResponse.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('error')) {
      return PunchResponse(
        error: json['error'],
      );
    } else {
      return PunchResponse(
        id: json['id'],
        images: (json['images'] as List<dynamic>)
            .map((img) => img['image'].toString())
            .toList(),
        punchType: json['punch_type'],
        timestamp: json['timestamp'],
        lat: json['lat'],
        long: json['long'],
        onLocation: json['on_location'],
        user: json['user'],
        task: json['task'],
      );
    }
  }

  bool get isSuccess => error == null;
}
class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  String selectedPriority = "all"; // all | low | medium | high

  int selectedTabIndex = 0;
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  final List<String> tabs = ["All", "Pending", "Completed"];
  bool isLoading = false;
  String selectedTaskId = '';
  String? punchedInTaskId;
int? userId;
  @override
  void initState() {
    super.initState();
    fetchTasks();

  }
  Future<void> fetchTasks() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    userId = prefs.getInt('userid') ?? 0;

    if (connectivityResult != ConnectivityResult.none) {
      // ✅ Online
      final response = await http.post(
        Uri.parse('https://admin.deineputzcrew.de/api/get_user_detail/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'token $token',
        },
        body: jsonEncode({"id": userId}),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (data['success']) {
        final List<dynamic> taskByDate = data['task_by_date'] ?? [];

        final List<Task> parsed = taskByDate
            .expand((dayData) {
          final String day = dayData['day'] ?? "";
          final String date = dayData['date'] ?? "";
          final List<dynamic> jsonTasks = dayData['tasks'] ?? [];
          return jsonTasks.map(
                (t) => Task.fromJson(t, day: day, date: date),
          );
        }).toList();

        //=== add data offline sql
        final db = DBHelper();
        await db.clearTasks(); // optional but recommended

        for (final task in parsed) {
          await db.insertTask(task.toMap());
        }

        // 🔥 SORT: Latest date + latest start time FIRST
        parsed.sort((a, b) {
          // ✅ Combine DATE + START TIME into DateTime
          DateTime parseDateTime(Task t) {
            try {
              final date = DateTime.parse(t.date!); // yyyy-MM-dd

              final parts = t.startTime.split(':');
              final hour = int.tryParse(parts[0]) ?? 0;
              final minute = int.tryParse(parts[1]) ?? 0;
              final second = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;

              return DateTime(
                date.year,
                date.month,
                date.day,
                hour,
                minute,
                second,
              );
            } catch (_) {
              return DateTime(1970);
            }
          }

          final dtA = parseDateTime(a);
          final dtB = parseDateTime(b);

          // 🔥 Latest FIRST
          return dtB.compareTo(dtA);
        });



        setState(() {
          tasks = parsed;
          applyFilter(); // keeps status + priority filters
          isLoading = false;
        });
      }

    } else {
      // ❌ Offline → load from SQLite
      //setState(() => isLoading = false);
      final offlineTasks = await DBHelper().getTasks();

      final parsed = offlineTasks
          .map((t) => Task.fromMap(t))
          .toList();

      setState(() {
        tasks = parsed;
        applyFilter();
        isLoading = false;
      });
    }
  }


  void applyFilter() {
    List<Task> temp = tasks;

    // 🔹 TODAY ONLY FILTER - Show only today's tasks
    final today = DateTime.now();
    final todayStr = "${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    temp = temp.where((t) => t.date == todayStr).toList();

    // 🔹 EXCLUDE COMPLETED TASKS - Ensure no completed status shows
    temp = temp.where((t) => (t.status ?? '').toLowerCase() != 'completed').toList();

    // 🔹 STATUS FILTER
    if (selectedTabIndex != 0) {
      final status = tabs[selectedTabIndex].toLowerCase();
      temp = temp.where((t) => t.status.toLowerCase() == status).toList();
    }

    // 🔹 PRIORITY FILTER
    if (selectedPriority != "all") {
      temp = temp
          .where((t) => t.priority.toLowerCase() == selectedPriority)
          .toList();
    }

    filteredTasks = temp;
  }
  int priorityCount(String priority) {
    return tasks
        .where((t) => t.priority.toLowerCase() == priority)
        .length;
  }

  Widget _priorityChip(String label) {
    final isSelected = selectedPriority == label.toLowerCase();

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.black,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w500,
      ),
      onSelected: (_) {
        setState(() {
          selectedPriority = label.toLowerCase();
          applyFilter();
        });
      },
    );
  }

  void onTabChanged(int index) {
    setState(() {
      selectedTabIndex = index;
      applyFilter();
    });
  }

  String formatTime(String time) {
    final parts = time.split(":");
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? "AM" : "PM";
    final formattedHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return "$formattedHour:${parts[1]} $period";
  }

  String calculateDuration(String start, String end) {
    final startParts = start.split(":").map(int.parse).toList();
    final endParts = end.split(":").map(int.parse).toList();

    final startMinutes = startParts[0] * 60 + startParts[1];
    final endMinutes = endParts[0] * 60 + endParts[1];
    final diff = endMinutes - startMinutes;

    if (diff >= 60 && diff % 60 == 0) {
      return "${diff ~/ 60} hr";
    } else if (diff >= 60) {
      return "${(diff / 60).toStringAsFixed(1)} hr";
    } else {
      return "$diff min";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "All Tasks",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tabs Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(tabs.length, (index) {
                final isSelected = selectedTabIndex == index;

                // Count logic
                int count = 0;
                if (index == 0) {
                  count = tasks.length; // All
                } else if (index == 1) {
                  count = tasks.where((t) => t.status== 'pending').length;
                } else if (index == 2) {
                  count = tasks.where((t) => t.status == 'completed').length;
                }

                return GestureDetector(
                  onTap: () => onTabChanged(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey.shade200 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          tabs[index],
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                            color: isSelected ? Colors.black : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),


            Wrap(
              spacing: 10,
              children: [
                _priorityChip("All"),
                _priorityChip("Low"),
                _priorityChip("Medium"),
                _priorityChip("High"),
              ],
            ),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    applyFilter();
                    filteredTasks = filteredTasks
                        .where((task) => task.taskName
                        .toString()
                        .toLowerCase()
                        .contains(value.toLowerCase()))
                        .toList();
                  });
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search Task",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Task List
            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return TaskCard(
                    title: task.taskName,
                    time: task.timeRange,
                    location: task.locationName,
                    duration: task.totalWorkTime,
                    highPriority: task.priority,
                    completed: task.status,
                    taskId: task.id,
                    punchIn: task.punchIn,
                    selectedTaskId: selectedTaskId ?? "",
                    punchedInTaskId: punchedInTaskId ?? "",
                    taskList: filteredTasks,
                    day: task.day,
                    date:task.date,
                    lat: task.lat,
                      longg: task.longg,
                    onTaskSelected: (id) {
                      final taskObj = filteredTasks.firstWhere((t) => t.id == id);

                      // ❌ Block if completed

                      // ✅ Allow selecting if it's the active punched-in task
                      setState(() {
                        selectedTaskId = id;

                        if(task.punchIn==true){
                         // startDashboardWorkTimer();

                        }
                      });
                    },


                    onPunchIn: () async {
                      setState(() {
                        selectedTaskId = task.id; // Select the task
                        // Mark as punched in
                      });



                      //startDashboardWorkTimer();
                    },

                    onPunchStart: () {
                      //stopTimer();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
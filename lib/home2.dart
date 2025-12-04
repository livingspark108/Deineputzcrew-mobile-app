/*
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:diveinpuits/settings.dart';
import 'package:diveinpuits/task.dart';
import 'package:diveinpuits/taskdetails.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import 'db_helper.dart';
import 'home.dart';
import 'task_model.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    AllTasksScreen(),
    SettingsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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

  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();


}

class _DashboardScreenState extends State<DashboardScreen> {

  static  Duration _workingDuration = Duration.zero;
  static DateTime? _punchInTime;

  bool _isLoadingBreak = false;
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


  @override
  void initState() {
    super.initState();
    loadUserData();
    // _restoreTimerState();
    syncOfflineActions();



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
    final breakDurationMillis = prefs.getInt('breakDuration') ?? 0;

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

      if (_onBreak) {
        // ✅ Restore break state
        _breakDuration = Duration(milliseconds: breakDurationMillis);
        _breakStartTime = DateTime.now().subtract(_breakDuration);

        _breakTimer?.cancel();
        _breakTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {
            _breakDuration = DateTime.now().difference(_breakStartTime!);
          });
        });

        // ✅ Adjust working duration so it excludes ongoing break
        _workingDuration = DateTime.now().difference(_punchInTime!) -
            (_pausedDuration + _breakDuration);
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
  static void startDashboardWorkTimer({bool isResuming = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!isResuming) {
      _punchInTime = DateTime.now();
      _pausedDuration = Duration.zero;
      await prefs.setString('punchInStartTime', _punchInTime!.toIso8601String());
      await prefs.setInt('pausedDuration', 0);
      await prefs.setBool('onBreak', false);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_onBreak && _punchInTime != null) {
        _workingDuration =
            DateTime.now().difference(_punchInTime!) - _pausedDuration;
        print("Working Duration: $_workingDuration");
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
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userid') ?? 0;
    token = prefs.getString('token');
    fetchTasks();
  }

  List<Task> taskList = [];
  List<Task> allTasks = [];
  Duration _breakDuration = Duration.zero;
  DateTime? _breakStartTime;
  Timer? _breakTimer;


  */
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
  }*//*



  Future<void> fetchTasks() async {
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
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        // ✅ Extract from "task_by_date" -> first element -> "tasks"
        final List<dynamic> taskByDate = data['task_by_date'] ?? [];
        final List<dynamic> jsonTasks =
        taskByDate.isNotEmpty ? taskByDate[0]['tasks'] ?? [] : [];

        final tasks = jsonTasks.map((t) => Task.fromJson(t)).toList();

        setState(() {
          allTasks = tasks;
          taskList = List.from(allTasks);
        });
        _restoreTimerState();
        // Save offline
        await DBHelper().clearTasks();
        for (var taskk in tasks) {
          await DBHelper().insertTask(taskk.toMap());
        }
      }
    } else {
      // ❌ Offline → load from SQLite
      final offlineTasks = await DBHelper().getTasks();
      setState(() {
        allTasks = offlineTasks.map((t) => Task.fromJson(t)).toList();
        taskList = List.from(allTasks);
      });
      _restoreTimerState();
    }


  }


  Future<void> syncOfflineActions() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      debugPrint("📴 No internet, skipping sync");
      return;
    }

    final pending = await DBHelper().getPunchActions();

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

        // Optional: remark for punch-out
        if (action.containsKey("remark") && action["remark"] != null) {
          request.fields["remark"] = action["remark"];
        }

        // Optional: attach image (punch only, not break)
        if (action["image_path"] != null &&
            action["image_path"].toString().isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath(
            "images",
            action["image_path"],
            filename: basename(action["image_path"]),
          ));
        }

        // Send to API
        final response = await request.send();
        final resBody = await http.Response.fromStream(response);
        debugPrint("📡 Sync response ($type): ${resBody.statusCode} ${resBody.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          await DBHelper().deletePunchAction(action["id"]);
          debugPrint("✅ Synced action: ${action['id']} ($type)");
        } else {
          debugPrint("❌ Failed sync ($type): ${resBody.body}");
        }
      } catch (e) {
        debugPrint("❌ Sync error: $e");
      }
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



  */
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
  }*//*

  */
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
  }*//*

  Future<bool> callBreakInApi(String taskId, BuildContext context) async {
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
        // ❌ Offline → Save locally
        await DBHelper().insertPunchAction({
          'task_id': taskId,
          'type': 'break_in',
          'lat': position.latitude.toStringAsFixed(6),
          'long': position.longitude.toStringAsFixed(6),
          'image_path': '', // optional for break
          'timestamp': DateTime.now().toIso8601String(),
        });

        await prefs.setBool('onBreak', true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Break-In saved offline. Will sync later.")),
        );
        return true;
      }

      // ✅ Online → Call API
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
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await prefs.setBool('onBreak', true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Break-In successful.")),
        );
        return true;
      } else {
        print('Break-in failed: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Break-In failed (${response.statusCode}).")),
        );
        return false;
      }
    } catch (e) {
      print("Break-in error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
        // ❌ Offline → Save locally
        await DBHelper().insertPunchAction({
          'task_id': taskId,
          'type': 'break_out',
          'lat': position.latitude.toStringAsFixed(6),
          'long': position.longitude.toStringAsFixed(6),
          'image_path': '',
          'timestamp': DateTime.now().toIso8601String(),
        });

        await prefs.setBool('onBreak', false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Break-Out saved offline. Will sync later.")),
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
          date:""
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
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 16),

          // Timer Row
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

          // Task info
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
            subtitle: Text(
              selectedTask.locationName.isNotEmpty
                  ? selectedTask.locationName
                  : 'No Task Selected',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const SizedBox(height: 12),

          // Clock In / Clock Out Buttons




          // Break + Clock Out Row
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
    final now = DateTime.now();
    final date = DateFormat('MMMM d, EEEE').format(now);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hello Thomas',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 14),
            _buildSearchBar(),
            const SizedBox(height: 18),
            buildTimerCard(context,date),
            const SizedBox(height: 28),
            _buildTaskHeader(context),
            const SizedBox(height: 14),
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


  Widget _buildTaskHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Recent Tasks',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Poppins')),
        TextButton(
          onPressed: () {

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AllTasksScreen()),
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
            duration: task.duration,
            highPriority: task.priority,
            completed: task.status,
            taskId: task.id,
            punchIn: task.punchIn,
            selectedTaskId: selectedTaskId ?? "",
            punchedInTaskId: punchedInTaskId ?? "",
            taskList: taskList,
            onTaskSelected: (id) {
              final taskObj = taskList.firstWhere((t) => t.id == id);

              // ❌ Block if completed

              // ✅ Allow selecting if it's the active punched-in task
              setState(() {
                selectedTaskId = id;

                if(task.punchIn==true){
                  startDashboardWorkTimer();

                }
              });
            },


            onPunchIn: () async {
              setState(() {
                selectedTaskId = task.id; // Select the task
                // Mark as punched in
              });



              startDashboardWorkTimer();
            },

            onPunchStart: () {
              //stopTimer();
            },
          );
        },
      );






    ;}




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
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool isSelected = false;


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
*/
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
        filename: basename(image.path),
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
  }*//*



  Future<void> _handlePunchIn(BuildContext context) async {
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

      // API request
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
        filename: basename(image.path),
      ));

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      Navigator.pop(context); // Close loading

      final Map<String, dynamic> responseData = await Future.sync(() {
        if (responseBody.body.isNotEmpty) {
          try {
            return jsonDecode(responseBody.body);
          } catch (e) {
            return {'error': 'Invalid response from server'};
          }
        }
        return {'error': 'Empty response from server'};
      });

      if (responseData.containsKey('error')) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(responseData['error'].toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      else {
        debugPrint("Punch-in response: $responseData");

        setState(() {
          isSelected = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Punch-in successful')),
        );

        widget.onPunchIn();
        setState(() {
          widget.punchedInTaskId = widget.taskId;
          widget.onTaskSelected(widget.taskId);
        });
        final timestamp = responseData['timestamp'] ?? '';
        final punchType = responseData['punch_type'] ?? '';
        final userId = responseData['user']?.toString() ?? '';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('punchedInTaskId', widget.taskId);

        setState(() {
          isSelected = true;
        });

        debugPrint("Timestamp: $timestamp, Punch Type: $punchType, User: $userId");
      }
    } catch (e) {
      Navigator.pop(context);
      debugPrint('Punch-in failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final bool isHigh = widget.highPriority.toLowerCase() == "high";
    final bool isCompleted =widget. completed.toLowerCase() == "completed";
    final bool isSelected = widget.selectedTaskId == widget.taskId;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        String storedPunchedInTaskId = prefs.getString('punchedInTaskId') ?? "";

        final bool isCompleted = widget.completed.toLowerCase() == "completed";
        final bool isCurrentPunchedIn = widget.taskId == storedPunchedInTaskId;

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

          if (!isCurrentPunchedIn) {
            await prefs.remove('punchedInTaskId');
            storedPunchedInTaskId = "";
          }

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
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: const TextStyle(
                            fontSize: 13, fontFamily: 'Poppins'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
*/

import 'dart:async';

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

  Duration _workingDuration = Duration.zero;
  DateTime? _punchInTime;
  bool _isLoadingBreak = false;
  String? punchedInTaskId;

  int userId = 0;
  String? token;
  List<dynamic> tasks = [];
  bool isClockedIn = false;
  bool isClockedOut = true;
  Timer? _timer;
  bool isOnBreak = false;
  Stopwatch stopwatch = Stopwatch();
  Timer? timer;

  bool _onBreak = false;

  Duration _pausedDuration = Duration.zero; // total break time
    DateTime? _breakStartTime; // when break started



  @override
  void initState() {
    super.initState();
    loadUserData();
    _restoreTimerState().then((_) {
      // Resume the timer only if there is a punched-in task and not on break
      if (!_onBreak && _punchInTime != null) {
        startDashboardWorkTimer(isResuming: true);
      }
    });

  }
  void resumeDashboardWorkTimer() async {
    if (_punchInTime != null) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _workingDuration = DateTime.now().difference(_punchInTime!) - _pausedDuration;
        });
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onBreak', false);
      setState(() => _onBreak = false);
    }
  }

  void startDashboardWorkTimer({bool isResuming = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (!isResuming) {
      _punchInTime = DateTime.now();
      _pausedDuration = Duration.zero;
      await prefs.setString('punchInStartTime', _punchInTime!.toIso8601String());
      await prefs.setInt('pausedDuration', 0);
      await prefs.setString('punchedInTaskId', selectedTaskId);
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_punchInTime != null) {
        setState(() {
          _workingDuration = DateTime.now().difference(_punchInTime!) - _pausedDuration;
        });
      }
    });
    setState(() => _onBreak = false);
  }



  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTaskId = prefs.getString('punchedInTaskId');
    final startTimeStr = prefs.getString('punchInStartTime');
    final pausedDurationMillis = prefs.getInt('pausedDuration') ?? 0;
    final onBreak = prefs.getBool('onBreak') ?? false;

    if (storedTaskId != null &&
        storedTaskId.isNotEmpty &&
        startTimeStr != null &&
        startTimeStr.isNotEmpty) {
      final startTime = DateTime.parse(startTimeStr);

      setState(() {
        selectedTaskId = storedTaskId;
        _punchInTime = startTime;
        _pausedDuration = Duration(milliseconds: pausedDurationMillis);
        _workingDuration = DateTime.now().difference(startTime) - _pausedDuration;
        _onBreak = onBreak;
      });
    } else {
      // Reset
      setState(() {
        _punchInTime = null;
        _workingDuration = Duration.zero;
        _pausedDuration = Duration.zero;
        _onBreak = false;
        selectedTaskId = "";
      });
    }
  }

  void pauseDashboardWorkTimer() async {
    if (_punchInTime != null) {
      _timer?.cancel();
      _pausedDuration += DateTime.now().difference(_punchInTime!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pausedDuration', _pausedDuration.inMilliseconds);
      await prefs.setBool('onBreak', true);
      setState(() => _onBreak = true);
    }
  }


  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _workingDuration = Duration.zero;
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userid') ?? 0;
    token = prefs.getString('token');
    fetchTasks();
  }

  List<Task> taskList = [];
  List<Task> allTasks = [];


  Future<void> fetchTasks() async {
    final response = await http.post(
      Uri.parse('https://admin.deineputzcrew.de/api/get_user_detail/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"id": userId}),
    );

    final data = jsonDecode(response.body);
    if (data['success']) {
      setState(() {
        allTasks = List<Task>.from(data['task'].map((t) => Task.fromJson(t)));
        taskList = List.from(allTasks);  // Initialize visible list to all tasks
      });
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


  Future<bool> callBreakInApi(String taskId, BuildContext context) async {
    try {
      // When starting break


// When ending break

      final position = await _getCurrentLocation();

      var uri = Uri.parse('https://admin.deineputzcrew.de/api/break-in/');
      var request = http.MultipartRequest('POST', uri);
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      request.headers['Authorization'] = 'token $token';
      request.fields['task_id'] = taskId;
      request.fields['lat'] = position.latitude.toString();
      request.fields['long'] = position.longitude.toString();

      // No image is added since you want image to be blank
      // If needed, leave it as is or comment out
      // request.files.add(await http.MultipartFile.fromPath('images', ''));

      var response = await request.send();

      if (response.statusCode == 200||response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Break In Successful.")),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onBreak', true);
        await Future.delayed(Duration(seconds: 1)); // Simulate delay

      } else {
        print('Break-in failed: ${response.statusCode}');
      }
    } catch (e) {
      print("Break-in error: $e");
    }
    return true;
  }
  Future<bool> callBreakOutApi(String taskId,BuildContext context) async {
    try {
      final position = await _getCurrentLocation();

      var uri = Uri.parse('https://admin.deineputzcrew.de/api/break-in/');
      var request = http.MultipartRequest('POST', uri);

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      request.headers['Authorization'] = 'token $token';


      request.fields['task_id'] = taskId;
      request.fields['lat'] = position.latitude.toString();
      request.fields['long'] = position.longitude.toString();

      // No image is added since you want image to be blank
      // If needed, leave it as is or comment out
      // request.files.add(await http.MultipartFile.fromPath('images', ''));

      var response = await request.send();

      if (response.statusCode == 200||response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('onBreak', false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Break In Successful.")),
        );
      } else {
        print('Break-in failed: ${response.statusCode}');
      }
    } catch (e) {
      print("Break-in error: $e");
    }
    await Future.delayed(Duration(seconds: 1)); // Simulate delay
    return true; // Or false if failed
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
            _buildTaskHeader(),
            const SizedBox(height: 14),
            _buildTaskList(),
          ],
        ),
      ),
    );
  }


  Widget buildTimerCard(BuildContext context, String date) {
    return StatefulBuilder(
      builder: (context, setState) {
        // Get selected task safely from allTasks
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
            punchIn: false,
            punchOut: false,
            breakIn: false,
            breakOut: false,
          ),
        );

        // Reset timer if no task selected
        if (selectedTask.id == 'N/A') {
          setState(() {
            _timer?.cancel();
            _workingDuration = Duration.zero;
            _pausedDuration = Duration.zero;   // also reset paused duration
                // also reset break duration
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
              )
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
                      value: _workingDuration.inHours.toString().padLeft(2, '0'),
                      label: 'Hrs',
                      color: Colors.blue),
                  const SizedBox(width: 6),
                  _TimerDigit(
                      value: (_workingDuration.inMinutes % 60)
                          .toString()
                          .padLeft(2, '0'),
                      label: 'Mins',
                      color: Colors.purple),
                  const SizedBox(width: 6),
                  _TimerDigit(
                      value: (_workingDuration.inSeconds % 60)
                          .toString()
                          .padLeft(2, '0'),
                      label: 'Secs',
                      color: Colors.pink),
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
              Visibility(
                visible: isClockedIn,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isClockedIn = false;
                        isClockedOut = true;
                      });
                    },
                    icon: const Icon(Icons.access_time),
                    label: const Text('Clock In',
                        style: TextStyle(fontFamily: 'Poppins')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

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
                                content:
                                Text('Please select a task before starting a break.')),
                          );
                          return;
                        }

                        setState(() => _isLoadingBreak = true);
                        final prefs = await SharedPreferences.getInstance();

                        if (_onBreak) {
                          // Break OUT
                          bool success =
                          await callBreakOutApi(selectedTaskId, context);
                          if (success) {
                            resumeDashboardWorkTimer();
                            await prefs.setBool('onBreak', false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Break ended. Timer resumed.')),
                            );
                          }
                        } else {
                          // Break IN
                          pauseDashboardWorkTimer();
                          bool success =
                          await callBreakInApi(selectedTaskId, context);
                          if (success) {
                            await prefs.setBool('onBreak', true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Break started. Timer paused.')),
                            );
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
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
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
                          final bool? punchedOut = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsScreen(
                                title: punchedInTask!.taskName,
                                time: punchedInTask.timeRange,
                                location: punchedInTask.locationName,
                                duration: punchedInTask.duration,
                                highPriority: punchedInTask.priority,
                                completed: punchedInTask.status,
                                taskId: punchedInTask.id,
                              ),
                            ),
                          );

                          if (punchedOut == true) stopTimer();
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
      },
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


  Widget _buildTaskHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Recent Tasks',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Poppins')),
        TextButton(
          onPressed: () {},
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
      } else {
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

        // ✅ If no task is punched in → punch this one in
        if (storedPunchedInTaskId.isEmpty) {
          await _handlePunchIn(context); // your punch-in function
          widget.onTaskSelected(widget.taskId);
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
                      if (widget.punchIn)
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

class Task {
  final String id;
  final String taskName;
  final String startTime;
  final String endTime;
  final String locationName;
  final String priority;
  final String status;
  final bool punchIn;
  final bool punchOut;
  final bool breakIn;
  final bool breakOut;

  Task({
    required this.id,
    required this.taskName,
    required this.startTime,
    required this.endTime,
    required this.locationName,
    required this.priority,
    required this.status,
    required this.punchIn,
    required this.punchOut,
    required this.breakIn,
    required this.breakOut,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      taskName: json['task_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      locationName: json['location_name'],
      priority: json['priority'],
      status: json['status'],
      punchIn: json['punch_in'],
      punchOut: json['punch_out'],
      breakIn: json['break_in'],
      breakOut: json['break_out'],
    );
  }

  String get duration {
    final start = DateTime.tryParse("2000-01-01 $startTime");
    final end = DateTime.tryParse("2000-01-01 $endTime");
    if (start != null && end != null) {
      final diff = end.difference(start);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
    return '0h 0m';
  }

  String get timeRange => "$startTime - $endTime";

  bool get isHighPriority => priority.toLowerCase() == 'high';
  bool get isCompleted => status.toLowerCase() == 'completed';
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

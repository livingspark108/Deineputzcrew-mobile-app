/*
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

  int userId = 0;
  String? token;
  List<dynamic> tasks = [];
  bool isClockedIn = false;
  bool isClockedOut = true;
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    loadUserData();
  }
  void startTimer() {
    _punchInTime = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _workingDuration = DateTime.now().difference(_punchInTime!);
      });
    });
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

  Future<void> fetchTasks() async {
    final response = await http.post(
      Uri.parse('https://admin.deineputzcrew.de/api/get_user_detail/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"id": userId}),
    );

    final data = jsonDecode(response.body);
    if (data['success']) {
      setState(() {
        taskList = List<Task>.from(data['task'].map((t) => Task.fromJson(t)));
      });
    }
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

        Position? currentPosition;




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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(date,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins')),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                      'Working',
                      style: TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Poppins'),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimerDigit(
                      value: _workingDuration.inHours.toString().padLeft(2, '0'),
                      label: 'Hrs',
                      color: Colors.blue),
                  const SizedBox(width: 6),
                  _TimerDigit(
                      value: (_workingDuration.inMinutes % 60).toString().padLeft(2, '0'),
                      label: 'Mins',
                      color: Colors.purple),
                  const SizedBox(width: 6),
                  _TimerDigit(
                      value: (_workingDuration.inSeconds % 60).toString().padLeft(2, '0'),
                      label: 'Secs',
                      color: Colors.pink),
                ],
              ),

              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Braj Kishori',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins')),
                subtitle: const Text('Redesign Home Page',
                    style: TextStyle(fontFamily: 'Poppins')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const SizedBox(height: 12),


              Visibility(
                visible: isClockedIn, // Show only if not clocked in
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        isClockedIn = false;
                        isClockedOut = true;
                      });

                      // Your custom logic
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

              Visibility(
                visible: isClockedOut,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.free_breakfast, color: Colors.orange),
                        label: const Text('Go for Break',
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.orange)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {

                          */
/*setState(() {
                            isClockedIn = true;
                            isClockedOut = false;


                          });*//*

                          */
/*          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailsScreen(
                                title: tasks[0].title,
                                time: tasks[0].,
                                location: location,
                                duration: duration,
                                highPriority: highPriority,
                                completed: completed,
                                taskId: taskId,
                              ),
                            ),
                          );*//*



                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Clock Out',
                            style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                      ),
                    ),
                  ],
                ),
              ),


              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoBox(title: '10:03', subtitle: 'Clock In'),
                  _InfoBox(title: '--', subtitle: 'Clock Out'),
                  _InfoBox(title: '00:42:18', subtitle: 'Break'),
                ],
              )
            ],
          ),
        );
      },
    );
  }


  Widget _buildSearchBar() {
    return TextField(
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
        physics:const NeverScrollableScrollPhysics(),
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
            selectedTaskId: selectedTaskId,
            onTaskSelected: (id) {
              setState(() {
                selectedTaskId = id;
              });
            },
            onPunchIn: () {
              print("Punching in for task ID: ${task.id}");
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




class TaskCard extends StatelessWidget {
  final String taskId;
  final String title;
  final String time;
  final String location;
  final String duration;
  final String highPriority;
  final String completed;
  final bool punchIn;
  final String selectedTaskId;
  final Function(String) onTaskSelected;
  final VoidCallback onPunchIn;

  const TaskCard({
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
    required this.onTaskSelected,
    required this.onPunchIn,
  });

  Future<void> _handlePunchIn(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      final position = await Geolocator.getCurrentPosition();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://admin.deineputzcrew.de/api/punch-in/'),
      );

      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      request.headers['Authorization'] = 'token $token';
      request.fields['task_id'] = taskId;
      request.fields['lat'] = position.latitude.toStringAsFixed(4);
      request.fields['long'] = position.longitude.toStringAsFixed(4);

      request.files.add(await http.MultipartFile.fromPath(
        'images',
        image.path,
        filename: basename(image.path),
      ));

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Punch-in successful')),
        );

        // 🔔 Start timer after successful punch-in
        onPunchIn();

        // Optional debug
        final timestamp = responseData['timestamp'] ?? '';
        final punchType = responseData['punch_type'] ?? '';
        final userId = responseData['user']?.toString() ?? '';

        debugPrint("Timestamp: $timestamp, Punch Type: $punchType, User: $userId");
      }
    } catch (e) {
      debugPrint('Punch-in failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHigh = highPriority.toLowerCase() == "high";
    final bool isCompleted = completed.toLowerCase() == "completed";
    final bool isSelected = selectedTaskId == taskId;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (punchIn) {
          onTaskSelected(taskId); // Select already punched-in task
        } else {
          _handlePunchIn(context); // Initiate punch-in
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
          color: isHigh ? null : Colors.white,
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
        ),
        child: Row(
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
                          title,
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
                      if (punchIn)
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
                        time,
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
                          location,
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
                  duration,
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
*/

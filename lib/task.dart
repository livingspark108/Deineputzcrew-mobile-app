import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  int selectedTabIndex = 0;
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> filteredTasks = [];
  final List<String> tabs = ["All", "Pending", "Completed"];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTasks();

  }

  Future<void> fetchTasks() async {
    setState(() => isLoading = true);
    const url = 'https://admin.deineputzcrew.de/api/get_user_detail/';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"id": 9}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> jsonTasks = data['task'];

      final parsed = jsonTasks.map((task) {
        final start = task['start_time'];
        final end = task['end_time'];
        return {
          "title": task["task_name"],
          "time": "${formatTime(start)} to ${formatTime(end)}",
          "location": task["location_name"],
          "duration": calculateDuration(start, end),
          "priority": task["priority"], // Modify if you want to check actual priority
          "status": task["status"].toString().capitalize(),
        };
      }).toList();

      setState(() {
        tasks = parsed;
        applyFilter();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print("Failed to load tasks: ${response.body}");
    }
  }

  void applyFilter() {
    if (selectedTabIndex == 0) {
      filteredTasks = tasks;
    } else {
      filteredTasks = tasks
          .where((task) =>
      task['status'].toString().toLowerCase() ==
          tabs[selectedTabIndex].toLowerCase())
          .toList();
    }
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
                  count = tasks.where((t) => t['status'] == 'Pending').length;
                } else if (index == 2) {
                  count = tasks.where((t) => t['status'] == 'Completed').length;
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
                        .where((task) => task['title']
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
                  return _TaskCard(
                    title: task["title"],
                    time: task["time"],
                    location: task["location"],
                    duration: task["duration"],
                    highPriority: task["priority"],
                    status: task["status"],
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

extension CapExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}

// Task Card Widget
class _TaskCard extends StatelessWidget {
  final String title;
  final String time;
  final String location;
  final String duration;
  final String highPriority; // comes from API now
  final String status;     // comes from API now

  const _TaskCard({
    required this.title,
    required this.time,
    required this.location,
    required this.duration,
    required this.highPriority,
    required this.status,
  });

  IconData getStatusIcon() {
    if (status.toLowerCase() == "completed") return Icons.check_circle;
    if (status.toLowerCase() == "wip") return Icons.crop_square_rounded;
    return Icons.circle_outlined;
  }

  Color getStatusColor() {
    if (status.toLowerCase() == "completed") return Colors.green;
    if (status.toLowerCase() == "wip") return Colors.orange;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, Colors.orange.shade50])
            ,
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(getStatusIcon(), color: getStatusColor(), size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: Colors.grey)),

                   Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(highPriority!.toString(),
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(location,
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 13)),
                    ),
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Text(duration,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

